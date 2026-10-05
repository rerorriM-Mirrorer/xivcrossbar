-- Contributing author: A. Run from the standalone XIVCrossbar repository root.
-- These regressions execute real addon code with Windower services stubbed;
-- they do not establish controller comfort or live FFXI acceptance.
for _, path in ipairs({
    'tests/xivcrossbar_profile_gate.lua',
    'tests/xivcrossbar_custom_actions.lua',
    'tests/xivcrossbar_layers.lua',
    'tests/xivcrossbar_pages.lua',
    'tests/xivcrossbar_drag.lua',
    'tests/xivcrossbar_sparse_ui.lua',
    'tests/xivcrossbar_visibility.lua',
    'tests/xivcrossbar_presentation.lua',
}) do
    dofile(path)
end
