# Historical Travel/Utility generator

This is the final `build_utility_pages.py` from the review archive. The main
player code already contains the Quick Switch stale-return correction. The
generator is optional development material; no generated XML is installed.

Its original default paths point into historical test packs, intentionally not
carried into the runtime. Supply explicit paths to a copy of the current file:

```text
python3 experiments/travel/build_utility_pages.py --job-file <current-WHM-NOSUB.xml> --output <new-WHM-NOSUB.xml>
```

The generator retains existing combat/Warp actions and refuses occupied
prototype slots or conflicting Travel pages. Review the generated copy before
installing it. For `--with-ui`, also supply `--catalog` and `--catalog-output`;
that optional Utility action needs the separate later AddonToggle 2.0 backend.
The captured profiles and catalog are authoritative for the first Lua test.
