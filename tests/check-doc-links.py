"""Every relative link in the README and docs/ points at a file that exists,
and every #anchor at a heading that exists, the way GitHub names them."""

import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
pages = [root / "README.md", *sorted((root / "docs").glob("*.md"))]


def anchors(page):
    """GitHub's anchor for each heading: lower case, punctuation and emoji
    removed, spaces turned into hyphens, repeats numbered."""
    seen = {}
    found = set()
    fenced = False
    for line in page.read_text().splitlines():
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        match = re.match(r"^#{1,6}\s+(.*?)\s*#*\s*$", line)
        if fenced or not match:
            continue
        slug = re.sub(r"[^\w\- ]", "", match.group(1).lower()).replace(" ", "-")
        count = seen.get(slug, 0)
        seen[slug] = count + 1
        found.add(slug if count == 0 else f"{slug}-{count}")
    return found


problems = []
for page in pages:
    text = re.sub(r"```.*?```", "", page.read_text(), flags=re.S)
    for target in re.findall(r"\]\(([^)\s]+)\)", text):
        if re.match(r"[a-z]+:", target):
            continue
        path, _, anchor = target.partition("#")
        dest = (page.parent / path).resolve() if path else page
        if not dest.exists():
            problems.append(f"{page.relative_to(root)}: {target}: no such file")
        elif anchor and dest.suffix == ".md" and anchor not in anchors(dest):
            problems.append(f"{page.relative_to(root)}: {target}: no such heading")

if problems:
    print("\n".join(problems))
    sys.exit(1)
