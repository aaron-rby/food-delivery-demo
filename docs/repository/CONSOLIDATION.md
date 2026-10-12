# One Savour repository

The full project and public website are now stored together in **aaron-rby/savour-delivery**.

- `backend/`: Java, tests, configuration example, driver instructions and run scripts.
- `database/`: Oracle schema, sample data, setup and review queries.
- `docs/`: guides, relations, EER, evidence, course presentation and this preservation record.
- `frontend/`: the local Java-served interface.
- `frontend/site/`: the original public website, including its API configuration and README.
- `.github/workflows/pages.yml`: publishes only frontend/site to GitHub Pages.

Both repositories' Git histories are ancestors of the consolidated main branch. `MERGE_MANIFEST.json` records every tracked input file, its destination and its SHA-256 at copying time. README/link updates after copying are deliberate; the original root README is retained at original-full-readme.md. The original public README is retained at original-site-readme.md.

Local Git bundles preserve both pre-consolidation histories as an additional backup. Actual Oracle credentials and the locally installed JDBC driver remain outside tracked files.

GitHub Pages hosts the frontend. The Java/Oracle server runs on the project computer and is shared over the configured temporary HTTPS tunnel; the machine, Oracle, Java and cloudflared must keep running. A restarted tunnel changes its URL: update frontend/site/backend-config.js and push to main.
