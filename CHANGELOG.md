# Changelog

All notable changes to this project are documented in this file.

## 1.1.0

- Maintenance update.

## 1.0.9

- Maintenance update.

## 1.0.8

- Release RealmRegionTag 1.0.5
- Release RealmRegionTag 1.0.2
- Release RealmRegionTag v1.0.1
- Rename addon to RealmRegionTag
- Add license section to README
- Add MIT license
- Move images into asset folder and exclude assets from packaging
- Add screenshot to README
- Exclude screenshot from release package
- Add addon screenshot
- Add gitignore and release packaging workflow
- Initial commit
- Updated addon version metadata.

## Unreleased

- Added `/rrt us` to toggle how US realm tags are displayed.
- Saved the selected US display mode across reloads and restarts.
- Updated addon version metadata.

## 1.0.7 - 2026-04-03

- Added a simple slash command toggle for US realm display mode.
- US realms can now be shown either as a single `US` tag or split as `USE`, `USC`, `USM`, and `USP`.
- Persisted the selected mode with addon saved variables.

## 1.0.5

- Released 1.0.5

## 1.0.5 - 2026-03-16

- Split US realms into `USE`, `USC`, `USM`, and `USP` instead of treating them all as a single `US` group.
- Kept Oceanic, Brazil, and Latin America realms as separate tags on top of the new US timezone split.
- Updated the displayed tag labels to use the explicit US timezone codes in the Premade Groups list.

## 1.0.2 - 2026-03-12

- Fixed leader region detection when the group leader is on the same realm as the player.
- Fallback now uses the player's current realm to determine the leader's region when the leader name does not include a realm suffix.

## 1.0.1 - 2026-03-12

- Added the initial tagged release for RealmRegionTag.
- Published the renamed addon under the `RealmRegionTag` project and addon folder name.
