# Usage: source scripts/summariseCrabLog.sh [--names "<CATEGORY|CATEGORY>"] <check log> [<check log> ...]
# One line per CRAB task from a checkSubmission.sh log, grouped so the tasks needing attention come first.
# Works on old logs too, so you can re-summarise without calling crab status again.
# --names prints only the names of tasks in the given categories (e.g. FAILED), one per line, for use in other scripts

_want=""
if [[ $1 == "--names" ]]; then _want=$2; shift 2; fi

for _crablog in "$@"; do
    awk -v want="$_want" '
    function flush() {
        if (name == "") return
        n++; names[n] = name
        if (length(name) > w) w = length(name)
        line[n] = describe()
        name = ""; server = ""; sched = ""; msg = ""; codes = ""; tape = 0; nodir = 0; age = ""; purged = 0
        delete jobs; delete probe; njobtot = 0; nprobetot = 0
    }
    function counts(arr, tot,   s, out) {
        out = ""
        for (s in arr) out = out ", " arr[s] " " s
        return substr(out, 3)
    }
    function describe(   active, s, done, failed) {
        if (nodir)                                    { cat[n] = "NO CRAB DIR"; return "crab_ directory not found" }
        if (purged && server ~ /REFUSED|FAILED|KILLED/) { cat[n] = server;    return "last known status, task submitted " age " days ago" (tape ? " (input on TAPE)" : "") }
        if (purged)                                   { cat[n] = "PURGED";      return "submitted " age " days ago, job details purged from the scheduler after 40 days" }
        if (server == "")                             { cat[n] = "UNKNOWN";     return (msg != "" ? msg : "no status from crab (proxy expired?)") }
        if (server ~ /REFUSED|FAILED|KILLED/ && njobtot == 0) {
            cat[n] = server
            return (tape ? "input on TAPE only - recall to disk, then submit fresh (resubmit will not work)" : msg)
        }
        if (njobtot == 0) { cat[n] = "PROBING"; return (nprobetot ? "probe jobs: " counts(probe) : "waiting to start, scheduler " sched) }
        done = jobs["finished"] + 0; failed = jobs["failed"] + jobs["killed"]
        active = njobtot - done - failed
        s = done "/" njobtot " finished"
        if (failed) s = s ", " failed " failed" (codes != "" ? " (exit" codes ")" : "")
        for (st in jobs) if (st != "finished" && st != "failed" && st != "killed") s = s ", " jobs[st] " " st
        if (active > 0)  cat[n] = "RUNNING"
        else if (failed) { cat[n] = "FAILED"; s = s " - crab resubmit" }
        else             cat[n] = "DONE"
        return s
    }
    # one "state  pct% (n/N)" entry, on the status line itself or a continuation line
    function addstate(txt, arr,   st, c) {
        sub(/^.*status:[ \t]*/, "", txt); sub(/^[ \t]+/, "", txt)
        split(txt, f, /[ \t]+/); st = f[1]
        if (!match(txt, /\( *[0-9]+\//)) return 0
        c = substr(txt, RSTART + 1, RLENGTH - 2); gsub(/ /, "", c)
        arr[st] += c
        return c + 0
    }
    /^Processing: /                  { flush(); name = $2; next }
    /^Skipping /                     { flush(); name = $2; sub(/:$/, "", name); nodir = 1; flush(); next }
    /^All directories processed/     { flush(); next }
    /^Status on the CRAB server:/    { server = $NF }
    /^Status on the scheduler:/      { sched = $NF }
    /^Jobs status:/                  { block = "jobs";  njobtot   += addstate($0, jobs);  next }
    /^Probe Jobs status:/            { block = "probe"; nprobetot += addstate($0, probe); next }
    block != "" && /^[ \t]+[A-Za-z]+[ \t]+[0-9.]+%/ {
        if (block == "jobs") njobtot += addstate($0, jobs); else nprobetot += addstate($0, probe)
        next
    }
    { block = "" }
    /jobs failed with exit code/     { codes = codes " " $NF "x" $1 }
    /TAPE/                           { tape = 1 }
    /^Task was submitted [0-9]+ days ago/ { age = $4 }
    /^Files are purged from Grid scheduler/ { purged = 1 }
    /^(Warning|Error|ERROR)/ && msg == "" { msg = $0; sub(/^[A-Za-z]+:[ \t]*/, "", msg); msg = substr(msg, 1, 100) }
    END {
        flush()
        if (want != "") { for (i = 1; i <= n; i++) if (cat[i] ~ ("^(" want ")$")) print names[i]; exit }
        split("NO CRAB DIR,UNKNOWN,SUBMITREFUSED,SUBMITFAILED,KILLED,FAILED,PROBING,RUNNING,DONE,PURGED", order, ",")
        for (o = 1; o in order; o++) {
            for (i = 1; i <= n; i++) if (cat[i] == order[o]) { printf "  %-13s %-" w "s  %s\n", cat[i], names[i], line[i]; tally[cat[i]]++; seen[i] = 1 }
        }
        for (i = 1; i <= n; i++) if (!seen[i]) { printf "  %-13s %-" w "s  %s\n", cat[i], names[i], line[i]; tally[cat[i]]++ }
        t = ""; for (o = 1; o in order; o++) if (order[o] in tally) t = t ", " tally[order[o]] " " order[o]
        printf "  -> %d tasks: %s\n", n, substr(t, 3)
    }' "$_crablog"
done
