#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import { writeFileSync } from "node:fs";

const USAGE = "Uso: node measure.mjs OWNER/REPO [--days 14] [--max-runs 500] [--out archivo.json]";
const OS_MULTIPLIER = { linux: 1, windows: 2, macos: 10, "self-hosted": 0 };

function parseArgs(argv) {
  const [repo, ...rest] = argv;
  if (!repo || !/^[\w.-]+\/[\w.-]+$/.test(repo)) {
    console.error(USAGE);
    process.exit(1);
  }
  const options = { repo, days: 14, maxRuns: 500, out: null };
  for (let i = 0; i < rest.length; i += 2) {
    const [flag, value] = [rest[i], rest[i + 1]];
    if (value === undefined) {
      console.error(USAGE);
      process.exit(1);
    }
    if (flag === "--days") options.days = Number(value);
    else if (flag === "--max-runs") options.maxRuns = Number(value);
    else if (flag === "--out") options.out = value;
    else {
      console.error(`Opcion desconocida: ${flag}\n${USAGE}`);
      process.exit(1);
    }
  }
  return options;
}

function ghJsonLines(path, jq) {
  const output = execFileSync("gh", ["api", "--paginate", path, "--jq", jq], {
    encoding: "utf8",
    maxBuffer: 256 * 1024 * 1024,
  });
  return output.split("\n").filter(Boolean).map((line) => JSON.parse(line));
}

function ghJson(path) {
  return JSON.parse(execFileSync("gh", ["api", path], { encoding: "utf8" }));
}

function runnerOs(labels) {
  const joined = labels.join(" ").toLowerCase();
  if (joined.includes("self-hosted")) return "self-hosted";
  if (joined.includes("windows")) return "windows";
  if (joined.includes("macos")) return "macos";
  return "linux";
}

function percentile(sortedValues, p) {
  if (sortedValues.length === 0) return 0;
  const index = Math.min(sortedValues.length - 1, Math.ceil((p / 100) * sortedValues.length) - 1);
  return sortedValues[Math.max(0, index)];
}

function round(value) {
  return Math.round(value * 10) / 10;
}

function summarize(jobs) {
  const durations = jobs.map((job) => job.minutes).sort((a, b) => a - b);
  const sum = (field) => jobs.reduce((total, job) => total + job[field], 0);
  return {
    jobs: jobs.length,
    minutes: round(sum("minutes")),
    billedMinutes: sum("billedMinutes"),
    roundingWasteMinutes: round(sum("roundingWasteMinutes")),
    cancelledMinutes: sum("cancelledMinutes"),
    p50Minutes: round(percentile(durations, 50)),
    p90Minutes: round(percentile(durations, 90)),
  };
}

function groupBy(items, keyOf) {
  const groups = new Map();
  for (const item of items) {
    const key = keyOf(item);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(item);
  }
  return groups;
}

function toJob(rawJob, run) {
  const os = runnerOs(rawJob.labels ?? []);
  const seconds = (Date.parse(rawJob.completed_at) - Date.parse(rawJob.started_at)) / 1000;
  const minutes = Math.max(0, seconds / 60);
  const roundedMinutes = Math.ceil(minutes);
  const billedMinutes = roundedMinutes * OS_MULTIPLIER[os];
  return {
    workflow: run.name,
    job: rawJob.name,
    os,
    conclusion: rawJob.conclusion,
    minutes,
    billedMinutes,
    roundingWasteMinutes: (roundedMinutes - minutes) * OS_MULTIPLIER[os],
    cancelledMinutes: rawJob.conclusion === "cancelled" ? billedMinutes : 0,
  };
}

function printTable(title, rows) {
  console.log(`\n${title}`);
  console.table(rows);
}

function main() {
  const { repo, days, maxRuns, out } = parseArgs(process.argv.slice(2));
  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
  const repoInfo = ghJson(`repos/${repo}`);

  console.error(`Leyendo corridas de ${repo} desde ${since}...`);
  const runs = ghJsonLines(
    `repos/${repo}/actions/runs?created=>=${since}&per_page=100`,
    ".workflow_runs[] | {id, name, event, status, pull_requests: [.pull_requests[].number]}",
  )
    .filter((run) => run.status === "completed")
    .slice(0, maxRuns);

  const jobs = [];
  runs.forEach((run, index) => {
    if (index % 25 === 0) console.error(`  jobs de la corrida ${index + 1}/${runs.length}`);
    const rawJobs = ghJsonLines(
      `repos/${repo}/actions/runs/${run.id}/jobs?filter=all&per_page=100`,
      ".jobs[] | select(.started_at != null and .completed_at != null) | {name, labels, conclusion, started_at, completed_at}",
    );
    jobs.push(...rawJobs.map((rawJob) => toJob(rawJob, run)));
  });

  const byWorkflow = [...groupBy(jobs, (job) => job.workflow)].map(([workflow, items]) => ({
    workflow,
    ...summarize(items),
  }));
  const byJob = [...groupBy(jobs, (job) => `${job.workflow} / ${job.job}`)].map(([job, items]) => ({
    job,
    os: items[0].os,
    ...summarize(items),
  }));
  byWorkflow.sort((a, b) => b.billedMinutes - a.billedMinutes);
  byJob.sort((a, b) => b.billedMinutes - a.billedMinutes);

  const runPrPairs = runs.flatMap((run) => run.pull_requests);
  const distinctPrs = new Set(runPrPairs);
  const result = {
    repo,
    private: repoInfo.private,
    since,
    days,
    runsAnalyzed: runs.length,
    truncatedAtMaxRuns: runs.length === maxRuns,
    total: summarize(jobs),
    runsPerPr: distinctPrs.size === 0 ? null : round(runPrPairs.length / distinctPrs.size),
    byWorkflow,
    byJob,
  };

  console.log(`Repo: ${repo} (${repoInfo.private ? "privado" : "publico"}), desde ${since}, ${runs.length} corridas`);
  if (!repoInfo.private) {
    console.log("Repo publico: los runners estandar no se facturan. Leer los minutos como tiempo de espera, no como costo.");
  }
  if (result.truncatedAtMaxRuns) {
    console.log(`Se alcanzo --max-runs ${maxRuns}: los totales no cubren todo el periodo.`);
  }
  printTable("Total", [result.total]);
  printTable("Por workflow", byWorkflow);
  printTable("Por job (top 20)", byJob.slice(0, 20));
  console.log(`Corridas por PR: ${result.runsPerPr ?? "sin corridas de PR"}`);
  console.log("billedMinutes: cada job redondeado al minuto y multiplicado por SO (linux 1, windows 2, macos 10, self-hosted 0).");

  if (out) {
    writeFileSync(out, JSON.stringify(result, null, 2));
    console.error(`JSON guardado en ${out}`);
  }
}

main();
