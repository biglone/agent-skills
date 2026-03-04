## Summary

- 

## Validation

- [ ] `bash -n scripts/install.sh scripts/update.sh`
- [ ] `python3 -m py_compile scripts/merge-skill.py`
- [ ] `bash scripts/validate-skills.sh`
- [ ] If touching Windows scripts, verify `install.ps1/update.ps1` path in CI

## Release Impact Checklist

- [ ] If install/update behavior changed, `scripts/manifest/version.txt` is bumped
- [ ] New env vars are documented in `README.md` (default + valid values)
- [ ] Backward compatibility is stated (`preview` default, no breaking overwrite)
- [ ] CI coverage includes changed behavior (Linux and Windows)

## Notes

- 
