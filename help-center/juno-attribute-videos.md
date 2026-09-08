# Attribute creator TikTok videos in Juno (Support)

Support can attribute existing creator TikToks to a campaign or 1:1 contract from **Juno** (the dash chatbot). This is the same path Shaheer uses in the creator database: **Adjust attribution** on a post.

Ticket: [ENG-11415](https://linear.app/growi/issue/ENG-11415/juno-ai-attribute-creator-videos-to-a-contract-shaheer-edit-user)

## When to use it

A brand or agency pastes TikTok links and asks to put them on a campaign or contract (example: Uptickk / Talia → Patricks, or Beforeyouspeak contract EA4269).

The videos must **already exist in Growi** and be tied to that creator. Juno will not scrape new posts or guess a brand by name.

## What to tell the customer

1. Immediate ack: *working on this for you now, I'll update you here shortly.*
2. After Juno finishes: list what **linked** (campaign/contract name + cycle) and what **did not** (short reason).

## How to run it in Juno

Open Juno on the **brand org** (not the agency parent unless that is the org that owns the posts).

Ask something like:

> Attribute these TikToks to this creator's campaign:
> - https://www.tiktok.com/t/ZTU6EwLew/
> - https://www.tiktok.com/@mercercaiden/video/7682832387725724941

Juno calls `attribute_creator_videos` with those URLs.

- **One campaign/contract** for that creator → it uses it. Do not pick a cycle; Juno uses the cycle whose dates contain the video post date.
- **Several campaigns** → Juno lists them. Reply with the campaign or contract (name or id). Then it continues.
- **Cycle N** → do not pick Cycle 1/2/3 unless Juno says it could not match a date range.

Accepted link shapes: full `tiktok.com/@user/video/ID`, short `tiktok.com/t/...`, `vm`/`vt` links, or a bare video id.

## How to read the result

| Result | Meaning |
| --- | --- |
| Linked — `{campaign} / Cycle N` | Same write as the creator-database dropdown. |
| not in Growi | Post is not in Growi for this org yet. Ingest / wait for sync, then retry. |
| wrong creator for this organization | Video belongs to a different creator than this org's roster. |
| no matching cycle for the video post date | Post date sits outside every cycle window. Check campaign dates or attribute by hand in the creator database. |
| Creator has N campaigns. Please specify campaign_id. | Tell Juno which campaign/contract. |
| could not parse TikTok URL | Bad or unsupported link. |

## Manual fallback (Shaheer path)

If Juno cannot do it, use the creator database:

`/organization/{slug}/creators/database/{creatorId}` → the post row → **Adjust attribution** → campaign → cycle.

That UI loads `simple_affiliate` and POSTs `update_user_content_campaign_affiliate`. Juno uses those same two endpoints only.
