local defaults = {}
defaults.CustomActionSaveScope = 'global'

defaults.buttonbackgroundalpha = 150
defaults.iscompact = true

defaults.iconpack = 'default'
-- A: personal builds start with the extended profile; public defaults stay separate.
defaults.ControllerProfile = 'ps5-extended'
defaults.ControllerDevice = 1
-- A: Personal Test 6 compares direct messages with the existing keyboard route.
defaults.ControllerMessages = true
-- A: opt-in real keyboard IJKL experiment; ordinary DirectLink remains default.
defaults.ControllerRealKeys = false
-- A: the personal target button is R3; R2 remains the ordinary trigger.
defaults.ControllerTargetR2 = false
defaults.ControllerTargetR3 = true
defaults.PersonalTargetR3Migrated = false
-- A: migrate older base-PS5 selections once; later explicit choices persist.
defaults.PersonalProfileMigrated = false
defaults.on_logout_unload_addon = false
-- A: the shared wrapper honors the last departing client's preference.
defaults.on_unload_killahk = true
defaults.enable_superwarp_all = true

defaults.FrameSkip = 0
defaults.AllowSTPCForSelfTargetedActions = true

defaults.AutoCreateXML = true
defaults.UseAltLayout = false
defaults.AutoHideExtraBars = true
defaults.UseSharedSet = false

defaults.SkillchainIndicator = {}
defaults.SkillchainIndicator.Opacity = 220
defaults.SkillchainIndicator.WindowWaitingColor = {}
defaults.SkillchainIndicator.WindowWaitingColor.Red = 237
defaults.SkillchainIndicator.WindowWaitingColor.Green = 28
defaults.SkillchainIndicator.WindowWaitingColor.Blue = 36
defaults.SkillchainIndicator.WindowOpenColor = {}
defaults.SkillchainIndicator.WindowOpenColor.Red = 15
defaults.SkillchainIndicator.WindowOpenColor.Green = 205
defaults.SkillchainIndicator.WindowOpenColor.Blue = 5

defaults.SpellLockoutIndicator = {}
defaults.SpellLockoutIndicator.Duration = 3.0
defaults.SpellLockoutIndicator.Opacity = 220
defaults.SpellLockoutIndicator.PrimaryColor = {}
defaults.SpellLockoutIndicator.PrimaryColor.Red = 200
defaults.SpellLockoutIndicator.PrimaryColor.Green = 200
defaults.SpellLockoutIndicator.PrimaryColor.Blue = 255
defaults.SpellLockoutIndicator.EndingFlashColor = {}
defaults.SpellLockoutIndicator.EndingFlashColor.Red = 15
defaults.SpellLockoutIndicator.EndingFlashColor.Green = 205
defaults.SpellLockoutIndicator.EndingFlashColor.Blue = 5

defaults.WeaponskillLockoutIndicator = {}
defaults.WeaponskillLockoutIndicator.Opacity = 220
defaults.WeaponskillLockoutIndicator.PrimaryColor = {}
defaults.WeaponskillLockoutIndicator.PrimaryColor.Red = 255
defaults.WeaponskillLockoutIndicator.PrimaryColor.Green = 150
defaults.WeaponskillLockoutIndicator.PrimaryColor.Blue = 0

defaults.JobAbilityLockoutIndicator = {}
defaults.JobAbilityLockoutIndicator.Opacity = 220
defaults.JobAbilityLockoutIndicator.FullLockoutColor = {}
defaults.JobAbilityLockoutIndicator.FullLockoutColor.Red = 220
defaults.JobAbilityLockoutIndicator.FullLockoutColor.Green = 30
defaults.JobAbilityLockoutIndicator.FullLockoutColor.Blue = 30
defaults.JobAbilityLockoutIndicator.PartialLockoutColor = {}
defaults.JobAbilityLockoutIndicator.PartialLockoutColor.Red = 15
defaults.JobAbilityLockoutIndicator.PartialLockoutColor.Green = 205
defaults.JobAbilityLockoutIndicator.PartialLockoutColor.Blue = 5

defaults.AutoAttackIndicator = {}
-- A: independent processing switch; opacity zero only hides the estimate.
defaults.AutoAttackIndicator.Enabled = true
defaults.AutoAttackIndicator.Opacity = 0
defaults.AutoAttackIndicator.PausedOpacity = 110
defaults.AutoAttackIndicator.BackgroundOpacity = 150
defaults.AutoAttackIndicator.PausedBackgroundOpacity = 75
defaults.AutoAttackIndicator.BeforeEstimateColor = {}
defaults.AutoAttackIndicator.BeforeEstimateColor.Red = 220
defaults.AutoAttackIndicator.BeforeEstimateColor.Green = 30
defaults.AutoAttackIndicator.BeforeEstimateColor.Blue = 30
defaults.AutoAttackIndicator.PastEstimateColor = {}
defaults.AutoAttackIndicator.PastEstimateColor.Red = 15
defaults.AutoAttackIndicator.PastEstimateColor.Green = 205
defaults.AutoAttackIndicator.PastEstimateColor.Blue = 5

defaults.Hotbar = {}
defaults.Hotbar.Number = 6
defaults.Hotbar.HideEmptySlots = false
defaults.Hotbar.HideActionName = false
defaults.Hotbar.HideActionCost = false
defaults.Hotbar.HideActionElement = true
defaults.Hotbar.HideRecastAnimation = false
defaults.Hotbar.HideRecastText = false
defaults.Hotbar.HideBattleNotice = false


defaults.Theme = {}
defaults.Theme.BattleNotice = 'ffxiv'
defaults.Theme.Slot = 'ffxiv'
defaults.Theme.Frame = 'ffxiv'

defaults.Style = {}
defaults.Style.SlotAlpha = 100
defaults.Style.SlotSpacing = 6
defaults.Style.HotbarSpacing = 56
defaults.Style.OffsetX = 0
defaults.Style.OffsetY = 0

defaults.HotbarOffsets = {}
defaults.HotbarOffsets.AlternatePress = {}
defaults.HotbarOffsets.AlternatePress.X = 0
defaults.HotbarOffsets.AlternatePress.Y = 0
defaults.HotbarOffsets.DoublePress = {}
defaults.HotbarOffsets.DoublePress.X = 0
defaults.HotbarOffsets.DoublePress.Y = 0

defaults.Color = {}
defaults.Color.MpCost = {}
-- A: match the pale green used for defaulted custom-action fields.
defaults.Color.MpCost.Red = 194
defaults.Color.MpCost.Green = 253
defaults.Color.MpCost.Blue = 195
defaults.Color.MpCostInsufficient = {Red=255, Green=149, Blue=151}
defaults.Color.TpCost = {}
defaults.Color.TpCost.Red = 254
defaults.Color.TpCost.Green = 222
defaults.Color.TpCost.Blue = 0
defaults.Color.Feedback = {}
defaults.Color.Feedback.Opacity = 150
defaults.Color.Feedback.Speed = 30
defaults.Color.Disabled = {}
defaults.Color.Disabled.Opacity = 100

defaults.Texts = {}
defaults.Texts.Font = 'sans-serif'
defaults.Texts.Size = 7
defaults.Texts.OffsetX = 0
defaults.Texts.OffsetY = 0
defaults.Texts.Color = {}
defaults.Texts.Color.Alpha = 255
defaults.Texts.Color.Red = 255
defaults.Texts.Color.Green = 255
defaults.Texts.Color.Blue = 255
defaults.Texts.Stroke = {}
defaults.Texts.Stroke.Width = 2
defaults.Texts.Stroke.Alpha = 200
defaults.Texts.Stroke.Red = 20
defaults.Texts.Stroke.Green = 20
defaults.Texts.Stroke.Blue = 20
-- A: measure unfamiliar centered captions transparently; comparison: textsettle off.
defaults.TextSettling = true


-- A: this transport test prints actions instead of executing slot commands.
defaults.InputTest = false
defaults.InputTrace = false
-- A: wrapper and Lua must use the same modifier. Change with all clients
-- unloaded and the shared wrapper stopped; Apps preserves Ctrl shortcuts.
defaults.ControllerModifier = 'apps'
-- A: bare gameplay D-pad only; menus and trigger-held slots stay logical.
defaults.GameplayDPad = 'ijkl'
defaults.VisibilityMode = 'oninput' -- always, oninput, hidden
defaults.CrossbarScale = 1
-- A: endpoint text visibility remains the default; TextFade is the comparison.
defaults.Animation = {Enabled=true, TextFade=false, FadeIn=0.1, FadeOut=0.5, LoadFadeIn=2}

return defaults
