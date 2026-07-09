#!/usr/bin/env node

const childProcess = require("node:child_process");

const [, , prNumber, repo] = process.argv;

function fail(message) {
	console.error(`FAIL: ${message}`);
	process.exitCode = 1;
}

function execFile(command, args) {
	return childProcess.execFileSync(command, args, {
		encoding: "utf8",
		stdio: ["ignore", "pipe", "pipe"],
	});
}

function parseTableRow(line) {
	const trimmed = line.trim();
	if (!trimmed.startsWith("|") || !trimmed.endsWith("|")) return null;
	return trimmed
		.slice(1, -1)
		.split("|")
		.map((cell) => cell.trim());
}

function isSeparatorRow(cells) {
	return cells.every((cell) => /^:?-{3,}:?$/.test(cell));
}

function attachmentUrls(markdown) {
	const urls = [];
	const htmlImgPattern = /<img\b[^>]*\bsrc=["']([^"']+)["'][^>]*>/gi;
	const mdImgPattern = /!\[[^\]]*\]\(([^)]+)\)/g;
	let match;
	while ((match = htmlImgPattern.exec(markdown))) urls.push(match[1]);
	while ((match = mdImgPattern.exec(markdown))) urls.push(match[1]);
	return urls;
}

function tableRows(body) {
	const lines = body.split(/\r?\n/);
	const headerIndexes = [];
	for (let index = 0; index < lines.length; index += 1) {
		const cells = parseTableRow(lines[index]);
		if (!cells) continue;
		if (
			cells.length === 3 &&
			cells[0] === "Figma" &&
			cells[1] === "Before" &&
			cells[2] === "After"
		) {
			headerIndexes.push(index);
		}
	}
	if (headerIndexes.length !== 1) {
		fail(`expected exactly one "Figma | Before | After" table, found ${headerIndexes.length}`);
		return [];
	}

	const headerIndex = headerIndexes[0];
	const separator = parseTableRow(lines[headerIndex + 1] ?? "");
	if (!separator || separator.length !== 3 || !isSeparatorRow(separator)) {
		fail("visual evidence table is missing a valid markdown separator row");
		return [];
	}

	const rows = [];
	for (let index = headerIndex + 2; index < lines.length; index += 1) {
		const cells = parseTableRow(lines[index]);
		if (!cells) break;
		if (cells.length !== 3) {
			fail(`visual evidence row ${rows.length + 1} has ${cells.length} columns; expected 3`);
			continue;
		}
		rows.push(cells);
	}
	if (!rows.length) fail("visual evidence table has no data rows");
	return rows;
}

function validateBody(body) {
	if (!body.includes("## Visual evidence")) {
		fail("missing ## Visual evidence section");
	}
	if (!body.includes("## Validation")) {
		fail("missing ## Validation section");
	}
	if (!/Visual gate:\s*\d+\/100/.test(body)) {
		fail("missing Visual gate: N/100 line");
	}
	if (/Screenshot upload blocker/i.test(body)) {
		fail("PR body still contains screenshot upload blocker text");
	}

	const rows = tableRows(body);
	rows.forEach((cells, rowIndex) => {
		["Figma", "Before", "After"].forEach((column, columnIndex) => {
			const urls = attachmentUrls(cells[columnIndex]);
			if (!urls.length) {
				fail(`row ${rowIndex + 1} ${column} cell has no rendered image`);
				return;
			}
			const badUrl = urls.find(
				(url) => !url.startsWith("https://github.com/user-attachments/assets/"),
			);
			if (badUrl) {
				fail(`row ${rowIndex + 1} ${column} image is not a GitHub user attachment: ${badUrl}`);
			}
		});
	});
}

function validateComments(comments) {
	for (const comment of comments) {
		const body = comment.body ?? "";
		const hasAttachment = body.includes("github.com/user-attachments/assets/");
		const looksLikeScreenshotEvidence =
			/Screenshot evidence|Visual evidence|Figma references|Storybook light mode|Style PR Storybook output/i.test(
				body,
			);
		if (hasAttachment && looksLikeScreenshotEvidence) {
			fail(`screenshot evidence appears in a top-level PR comment: ${comment.url}`);
		}
	}
}

function main() {
	if (!prNumber || !repo) {
		console.error("Usage: validate-pr-body.js <pr-number> <owner/repo>");
		process.exit(2);
	}

	const json = execFile("gh", [
		"pr",
		"view",
		prNumber,
		"--repo",
		repo,
		"--json",
		"body,comments",
	]);
	const pr = JSON.parse(json);
	validateBody(pr.body ?? "");
	validateComments(pr.comments ?? []);

	if (process.exitCode) process.exit(process.exitCode);
	console.log(`PASS: PR #${prNumber} visual evidence body is valid`);
}

main();
