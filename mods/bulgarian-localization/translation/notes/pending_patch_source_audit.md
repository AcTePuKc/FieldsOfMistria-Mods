# Pending game-source audit

External reports may refer to localization keys added or corrected after the
currently extracted game assets. Do not add those keys manually until they can
be verified in an updated English source cache or game extraction.

## Reported tutorial title

- Reported key: `ui/tutorials/baby/title`
- Expected current English value: `Tutorial: Baby Care`
- Reported incorrect value in an earlier source: `Tutorial: Engagement Proposal`
- Status: present in the current 1.0.2 `zh-Hans` cache with the corrected
  value. It was absent from the older `fra`-only source inventory.
- Action: included in the reconciled 1.0.2 source catalog and Starter Kit;
  add the Bulgarian translation to the work files.
