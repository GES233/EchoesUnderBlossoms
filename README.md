# Echoes Under Blossoms

[简体中文](./README.zh_Hans.md) [日本語](/README.ja.md)

HanaShirabe is the romanized abbreviation of the Japanese phrase "花隠れの調べ (Hanakakure no Shirabe)", used to describe our web application. For English users, we refer to it as **Echoes Under Blossoms**.

A platform for excavating rarely circulated works from Visual Novels / Galgames or other media.

## Mission and Inspiration

> _Leave proof of having lived_
>
> —— Mai Mai Mai Mai Miao

Inspired by the work of [Mai Mai Mai Mai Miao(Riri)](https://space.bilibili.com/3494356619102794).
He's dedicated to unearthing buried obscure music, especially lost works from Japanese VN/Galgame.
Videos often focus on tracks where the author has disappeared and the source is hard to trace.

In addition to Riri, [HachimiWorld](https://github.com/HachimiWorld)[^hachimi] as a meme-driven community is also a source of inspiration, which is a community-driven Hachimi music player.
Hachimi music is a subculture phenomenon popular on the Chinese internet. It originated around 2023 during a dispute over the definition of "Hachimi" and subsequently evolved into a unique form of secondary creation, creating captivating remixes/MADs by deconstructing and reassembling specific audio and visual elements.
This music, often featuring catchy melodies and comedic elements, has quickly spread among young users.

Therefore, we plan to create a systematic, community-based platform to allow more users to participate in discovery and re-creation, rather than just individual sharing.

[^hachimi]: This organization focuses on developing a community-driven open-source meme culture music community.

## Features and Highlights

### Core Domain Objects

- **Proposal**
  - Users initiate excavation proposals for specific games, providing clues (such as historical records, author contacts) to help recover lost audio
  - Proposals have a lifecycle: Creation → Resource Gathering → Excavation → Validation → Closure/Abandonment → Supplementation
    - This also involves searching for authors and developers
  - Generally contributed by one or more users with clues, verified in an observational manner by other users and administrators (Spectators)
- **Audio Resource**
  - The main object of the proposal is the audio resource
  - Includes metadata of music tracks (composer, work, format, etc.)
  - Generally provides external links or the file itself (depending on available information)
  - Resources are associated with games, supporting search and re-creation
  - Re-creation and interpretation of audio resources involve the audio resource itself

Regarding authors and vendors, since many are lost and hard to retrieve, they will not be considered as **primary** business objects [this point needs discussion].
### Investigation Process

- Proposal Submission and Verification
  - The initiator(s) submit evidence proving the media may exist.
  - Platform review or senior community members conduct an investigation to ensure it is unique and valid, and then publicly available on the site.
- Proposal Investigation
  - A proposal has two content tracks: the "Discussion Pool" and the "Investigation Tree." Valuable content in the "Discussion Pool" will be posted to the "Investigation Tree."
  - The goal of the "Investigation Tree" is to organize a complete and mutually verifiable chain of evidence regarding the subject of the proposal's investigation.
- Investigation, Narrative and Archiving Cycle
  - When the nodes in the investigation tree reach a certain level, the lead author creates a timeline depicting the development of the incident.
  - The nodes in the timeline correspond to the nodes in the evidence (i.e., the chain of evidence and the content in the timeline are mutually convertible and have a clear topology). This ensures that any subsequent reversals are feasible.
  - When the investigation is stable and the timeline is complete, the lead author can create a "stable snapshot" for archiving. The latest snapshot will be publicly displayed.
  - The archive is not frozen; the emergence of subversive evidence will result in a reopened investigation (which will also affect the corresponding content in the timeline).
  - Proposals that lack sufficient evidence but are valuable will be subject to a "snapshot"

### Copyright

This project is for educational and research purposes only and does not encourage any infringement.
All audio resources must obtain author permission or comply with fair use.
The platform does not host unauthorized files; users are responsible for the compliance of uploaded content.
We reference community practices like [Lost Media Wiki](https://lostmediawiki.com/Home), emphasizing information sharing rather than distribution.

If there are copyright issues, please contact the administrator for removal.
If you are a composer or rights holder, welcome to contact us to authorize sharing your works!

## Technology Stack

- Backend: Elixir + Phoenix
- Interaction: Phoenix LiveView
- Database: SQLite
- Frontend: Tailwind CSS + DaisyUI

## Contributions

Welcome VN / Galgame enthusiasts and developers to participate! Contribution methods:

- Submit Issues: Report bugs or suggest new features
- New Features: Implement new proposal lifecycle events or UI components
- Submit Translations: We need Japanese translations!
- Content Contributions: After the platform launches, create proposals to share clues

## Contact Us

- GitHub: https://github.com/GES233/EchoesUnderBlossoms

Thank you for your attention, let's rediscover lost notes under the flower shadows together!
