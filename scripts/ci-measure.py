#!/usr/bin/env python3
"""Summarise Validate-fixtures runs: job time, queue wait, per-step means.

Usage: ci-measure.py <run-id> [<run-id> ...]   (needs an authenticated `gh`)
Only successful jobs are counted. Queue wait = job start - run creation.
"""
import collections
import datetime as dt
import json
import statistics as st
import subprocess
import sys


def ts(value):
    return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))


def main(run_ids):
    steps = collections.defaultdict(list)
    waits, durations = [], []
    for run_id in run_ids:
        out = subprocess.run(
            ["gh", "run", "view", run_id, "--json", "jobs,createdAt"],
            check=True, capture_output=True, text=True,
        ).stdout
        run = json.loads(out)
        created = ts(run["createdAt"])
        for job in run["jobs"]:
            if job["conclusion"] != "success" or not job.get("startedAt"):
                continue
            waits.append((ts(job["startedAt"]) - created).total_seconds())
            durations.append((ts(job["completedAt"]) - ts(job["startedAt"])).total_seconds())
            for step in job["steps"]:
                if step.get("startedAt") and step.get("completedAt"):
                    steps[step["name"]].append((ts(step["completedAt"]) - ts(step["startedAt"])).total_seconds())
    if not durations:
        sys.exit("no successful jobs found")
    print(f"jobs measured: {len(durations)}")
    print("job duration s : mean %.0f median %.0f max %.0f" % (st.mean(durations), st.median(durations), max(durations)))
    print("queue wait s   : mean %.0f median %.0f max %.0f" % (st.mean(waits), st.median(waits), max(waits)))
    print("step means (s):")
    for name, values in sorted(steps.items(), key=lambda kv: -st.mean(kv[1])):
        print(f"  {st.mean(values):6.0f}  n={len(values):3d}  {name}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
