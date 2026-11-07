# Outpost Zero: game data pack (v0.3, strict NASA split)

The pack has two kinds of files, kept apart on purpose:

| Class | Files | Rule |
|---|---|---|
| **NASA_DATA** | `nasa_data.json`, `sources.json` | Only values read on a NASA page. Each fact has the page id, the number, and what the page says. |
| **GAME_VALUE** | `game_constants.json`, `sites.json`, `equipment.json`, `loads.json`, `levels.json`, `events.json`, `lessons.json`, `crew.json`, `radio.json`, `badges.json` | Game design and our own formulas. Never call these NASA data. They point to NASA facts by id instead of copying the numbers. |

Other files: `credits.json`, `credits.md` (credits), `check_data.py` (checker), this README.

## Check it in ten seconds

```
python3 check_data.py
```

It confirms that every NASA fact cites a page on a nasa.gov site, every cited page exists in `sources.json`, and no game file claims to hold measured or published data.

## Using it in the game

```js
const load = f => fetch(f).then(r => r.json());
const nasa  = (await load('nasa_data.json')).facts;
const fact  = id => nasa[id].value;                    // e.g. fact('rad_gale_surface') -> 0.67
const gc    = await load('game_constants.json');
const sites = (await load('sites.json')).sites;
// a site's latitude: fact(site.nasa_fact_ids.lat)
```

Serve the folder with a static server (for example `python3 -m http.server`), because browsers block `fetch` on `file://` pages.

## Power model

```
generation_kw = peak_kw * daylight_curve(hour) * site.solar_factor * exp(-tau) * (1 - dust_on_panels)
battery_kwh  += generation_kw - sum(active_load_kw)      // one tick = one hour, clamp 0..capacity
warning when battery_pct < 20
```

`peak_kw` = solar irradiance (NASA, 586.2 W/m2) x 30 m2 x 0.25 = 4.4 kW, shown as DERIVED. `exp(-tau)` matches NASA: tau 3 lets about 5 percent of sunlight through.

## What is NOT NASA data (label it on screen and in the video)

- **GAME VALUE:** every cost, budget, load, output, event chance, battery and habitat numbers, the 25 mSv game limit, the 4 mSv solar particle spike, the game storm peak (tau 4.0), clear-sky tau 0.5, panel dust gain, starting stocks, crew size.
- **DERIVED:** panel peak output (4.4 kW), each site's sunlight factor (cos of latitude), the stylized storm curve.
- **Left out because no NASA page gave it:** elevations of Arcadia, Deuteronilus and Meridiani; site temperatures other than Gale (sites show the NASA global mean); radiation at any site except Gale (every site uses the Gale value); hygiene water per person; ice depth at Gale and Meridiani.

## Before you submit

- [ ] Open each of the 24 pages in `sources.json` and tick the Verify sheet in the spreadsheet. I read the pages through a summarizing tool, so a human must confirm each number.
- [ ] Open the challenge page and its Resources list: https://www.spaceappschallenge.org/2026/challenges/build-a-junior-astronaut-mission-trainer/ (the site blocked my tool). If it names required data sources, check these facts against them.
- [ ] Read the Project Submission Guide and Judging guide linked from the challenge page. The Participant Terms say you must cite every source used and identify licenses.
- [ ] Put the 24 source links in the submission description.
- [ ] Meridiani latitude prints as "-1.95" on the Mars24 page, read here as 1.95 S: confirm on another NASA page.
- [ ] Fill every `TODO` in `credits.json` (creators, links, tools, AI use) and the team names.
- [ ] Retune the game: crew needs are NASA values (about 3.6 kg oxygen, 10 kg water, 9.6 kg packaged food per sol for four people), but greenhouse, ice miner and starting stocks are game values.
- [ ] Label the Sample 1 screen "Concept mock-up", or remove the two `concept_only` loads.
- [ ] Say "adds", "unlocks" and "earn" for planned features, and say in Part 6 that the game has not been tested with students.
