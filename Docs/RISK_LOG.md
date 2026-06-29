# Risk Log

- Breathing visuals could conflict with exact hit-testing if visual morphs diverge too far from logical cells; mitigation: keep TesseraCore authoritative and deterministic.
- Daily generator quality may require hand-tuning tools to avoid boring or impossible boards; mitigation: add generator tests and curated seeds.
- StoreKit 2 and entitlement cache need careful offline behavior; mitigation: isolate purchase state from core gameplay.
- Xcode availability may vary in agent environments; mitigation: maintain Swift Package tests for core logic and mark Xcode builds unverified when unavailable.
