void Main() {
    startnew(MainCoro);
}

bool IsGameFocused = true;
bool IsOpenplanetMouseOver = false;
bool IsOpenplanetKeyboardFocus = false;
bool IsNotVehicleActionMap = false;
bool IsSpectatorActionMap = false;
bool IsKeyboardFocus = false;
int KeyboardInputIx = -1;

void MainCoro() {
    auto app = cast<CTrackMania>(GetApp());
    while (true) {
        yield();
        IsGameFocused = app.InputPort.IsFocused;
        IsOpenplanetMouseOver = app.InputPort.MouseVisibility > 1; // enum: auto, force hide, force show. (latter when openplanet ui hovered)
        // openplanet kb focus
        CInputDeviceDx8Keyboard@ KeyboardDevice;
        // if we don't have an index, find an index
        if (KeyboardInputIx < 0 || KeyboardInputIx >= int(app.InputPort.ConnectedDevices.Length)) FindKeyboardDevice(app.InputPort);
        @KeyboardDevice = cast<CInputDeviceDx8Keyboard>(app.InputPort.ConnectedDevices[KeyboardInputIx]);
        // if we still haven't found it, find the index (we'll update kb focus next frame)
        if (KeyboardDevice is null) FindKeyboardDevice(app.InputPort);
        else IsOpenplanetKeyboardFocus = KeyboardDevice.IsDisabled;
        // active when changing maps sometimes -- if we dont account for it, we'll trigger 'kb not focused' msg which is wrong
        IsSpectatorActionMap = app.InputPort.CurrentActionMap == "SpectatorMap";
        IsNotVehicleActionMap = !IsSpectatorActionMap && app.InputPort.CurrentActionMap != "Vehicle";
        IsKeyboardFocus = IsOpenplanetKeyboardFocus || (IsNotVehicleActionMap && mostRecentSeq !is null && mostRecentSeq.InGame);
    }
}

void FindKeyboardDevice(CInputPort@ input) {
    for (KeyboardInputIx = 0; KeyboardInputIx < input.ConnectedDevices.Length; KeyboardInputIx++) {
        if (cast<CInputDeviceDx8Keyboard>(input.ConnectedDevices[KeyboardInputIx]) !is null) {
            // Notify("kb found at " + KeyboardInputIx);
            return;
        }
    }
    // we didn't find it.
    KeyboardInputIx = -1;
}

const string PluginIcon = Icons::Bell;
const string MenuTitle = "\\$ff3" + PluginIcon + "\\$z " + Meta::ExecutingPlugin().Name;
const string MenuTitle2 = "\\$ff3" + Icons::BellO + "\\$z " + Meta::ExecutingPlugin().Name;
const string MenuTitleNoIcon = "\\$888" + Icons::ArrowsV + "\\$z " + Meta::ExecutingPlugin().Name;

int dynamicPeriodMs = 50;
const string DynamicMenuTitle() {
    uint frame = (Time::Now / dynamicPeriodMs) % 2;
    if (frame == 0) return MenuTitle;
    return MenuTitle2;
}

/** Render function called every frame intended only for menu items in `UI`. */
void RenderMenu() {
    bool clicked = UI::MenuItem(MenuTitleNoIcon, "", S_Enabled);
    DrawDinkDonkForMenu();
    if (clicked) S_Enabled = !S_Enabled;
}

/** Render function called every frame intended for `UI`.
*/
void RenderInterface() {
    if (!ShowWindow) return;
    if (UI::Begin(DynamicMenuTitle() + '###dinkdonk-main', ShowWindow)) {
        UI::Columns(2, "", false);
        DrawDebugInfoGlobalState();
        UI::NextColumn();
        if (UI::Button("Play Sound")) EnsureNotifSoundPlaying();
        if (UI::Button("Stop Sound")) EnsureNotifSoundNotPlaying();
        if (UI::Button("Start Draw Animations")) ShouldDrawAnimations = true;
        if (UI::Button("Stop Draw Animations")) ShouldDrawAnimations = false;
        UI::Columns(1);
        UI::Separator();
        if (UI::CollapsingHeader("UI Sequence Legend")) {
            for (uint i = 0; i < 12; i++) {
                UI::Text(Text::Format("%2d: ", i) + tostring(CGamePlaygroundUIConfig::EUISequence(i)));
            }
        }
        UI::Separator();
        DrawUISequenceLogTable();
    }
    UI::End();
}

void Render() {
    if (S_Enabled && ShouldDrawAnimations)
        RenderDinkDonk();
}

void Update(float dt) {
    DinkDonkUpdate();
}

void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}


void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(msg);
        UI::EndTooltip();
    }
}
