## What is it?!

This workflow checks the last 50 PRs in given repositories and ensures they are added as Things tasks.  The idea is to request new PRs and add them to designated lists in Things 3 for processing.

Note: Updates to a PR are not currently handled (e.g. if your review is requested after loading to Things, or a title changes)

## Variables

`CURRENT_GITHUB_USER` is your github username - it's used to identify PRs where review has been requested.  **Required**.

`REPO_CONFIG_*` define the repositories to include and a local path to them. Format as:
`repo_friendly_name,/path/to/local/repo` **Optional** (but nothing will happen unless you have one configured)

`TEAM_AUTHORS` is the group of users that are on your immediate team. Separate these reviews from others in your org for easier prioritization. Github usernames, comma separated.  **Optional**.

`THINGS_AUTH_TOKEN` is the URL Scheme token findable by going to Preferences -> Enable Things URL -> Manage.  **Required**.

## Future possible directions/alternative flows:

- Only get PRs from people on your team
- Put the PRs in the inbox for sorting instead of their dedicated lists
