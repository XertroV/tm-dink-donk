[Setting hidden]
bool S_Enabled = true;

[Setting hidden]
float S_Gain = 1.0;

[Setting hidden]
bool S_DrawFocusedWarningText = true;

[Setting hidden]
bool S_DrawDinkDonkImage = true;

[Setting hidden]
bool S_EnableRoundStartNotif = true;

enum FocusConditions {
    Never,
    GameUnfocused,
    KeyboardHasFocus,
    GameUnfocusedOrKeyboardHasFocus
}

[Setting hidden]
FocusConditions S_RoundStartNotifConditions = FocusConditions::GameUnfocused;



[SettingsTab name="Dink Donk" icon="Bell" order="1"]
void Render_S_DinkDonk_Main() {
    S_Enabled = UI::Checkbox("Enabled", S_Enabled);
    S_EnableRoundStartNotif = UI::Checkbox("Enable Round Start Notification Sound", S_EnableRoundStartNotif);

    UI::BeginDisabled(!S_EnableRoundStartNotif);
    S_RoundStartNotifConditions = DrawNotifConditionsCombo(S_RoundStartNotifConditions);
    UI::EndDisabled();

    S_Gain = UI::SliderFloat("Volume", S_Gain, 0, 2);

    UI::AlignTextToFramePadding();
    UI::Text("Demo:");

    if (UI::Button("Play Sound")) EnsureNotifSoundPlaying();
    UI::SameLine();
    if (UI::Button("Stop Sound")) EnsureNotifSoundNotPlaying();

    UI::Separator();

    S_DrawDinkDonkImage = UI::Checkbox("Draw Dink Donk Main Image", S_DrawDinkDonkImage);
    S_DrawFocusedWarningText = UI::Checkbox("Draw Focus Warning Text", S_DrawFocusedWarningText);

    UI::AlignTextToFramePadding();
    UI::Text("Demo:");

    if (UI::Button("Start Draw Animations")) ShouldDrawAnimations = true;
    UI::SameLine();
    if (UI::Button("Stop Draw Animations")) ShouldDrawAnimations = false;

    UI::AlignTextToFramePadding();
    UI::Text("ShouldDrawAnimations (Demo Active): " + (ShouldDrawAnimations ? Icons::Check : Icons::Times));

    tmpInputStr = UI::InputText("demo input", tmpInputStr);

    UI::Separator();

    UI::AlignTextToFramePadding();
    UI::Text("Debug Info:");
    DrawDebugInfoGlobalState();
}

[Setting hidden]
bool S_Enable_UISeq_None = false;

[Setting hidden]
bool S_Enable_UISeq_Playing = false;

[Setting hidden]
bool S_Enable_UISeq_Intro = false;

[Setting hidden]
bool S_Enable_UISeq_Outro = false;

[Setting hidden]
bool S_Enable_UISeq_Podium = false;

[Setting hidden]
bool S_Enable_UISeq_CustomMTClip = false;

[Setting hidden]
bool S_Enable_UISeq_EndRound = true;

[Setting hidden]
bool S_Enable_UISeq_PlayersPresentation = false;

[Setting hidden]
bool S_Enable_UISeq_UIInteraction = true;

[Setting hidden]
bool S_Enable_UISeq_RollingBackgroundIntro = false;

[Setting hidden]
bool S_Enable_UISeq_CustomMTClip_WithUIInteraction = false;

[Setting hidden]
bool S_Enable_UISeq_Finish = false;

// show the debug window
[Setting hidden]
bool ShowWindow = false;

[SettingsTab name="Advanced" icon="Cogs" order="50"]
void Render_S_Advanced() {
    UI::AlignTextToFramePadding();
    UI::Text("Dink Donk UI Sequences");
    UI::AlignTextToFramePadding();
    UI::TextWrapped("A notification will be active/sounded when these UI Sequences are active in non-local modes.\nFor Matchmaking, enable: EndRound\nFor KO (including COTD): UIInteraction");
    UI::Columns(4, "", false);
    UI::Separator();
    S_Enable_UISeq_None = UI::Checkbox("None", S_Enable_UISeq_None);
    UI::NextColumn();
    S_Enable_UISeq_Playing = UI::Checkbox("Playing", S_Enable_UISeq_Playing);
    UI::NextColumn();
    S_Enable_UISeq_Intro = UI::Checkbox("Intro", S_Enable_UISeq_Intro);
    UI::NextColumn();
    S_Enable_UISeq_Outro = UI::Checkbox("Outro", S_Enable_UISeq_Outro);
    UI::NextColumn();
    S_Enable_UISeq_Podium = UI::Checkbox("Podium", S_Enable_UISeq_Podium);
    UI::NextColumn();
    S_Enable_UISeq_CustomMTClip = UI::Checkbox("CustomMTClip", S_Enable_UISeq_CustomMTClip);
    UI::NextColumn();
    S_Enable_UISeq_EndRound = UI::Checkbox("EndRound", S_Enable_UISeq_EndRound);
    UI::NextColumn();
    S_Enable_UISeq_PlayersPresentation = UI::Checkbox("PlayersPresentation", S_Enable_UISeq_PlayersPresentation);
    UI::NextColumn();
    S_Enable_UISeq_UIInteraction = UI::Checkbox("UIInteraction", S_Enable_UISeq_UIInteraction);
    UI::NextColumn();
    S_Enable_UISeq_RollingBackgroundIntro = UI::Checkbox("RollingBackgroundIntro", S_Enable_UISeq_RollingBackgroundIntro);
    UI::NextColumn();
    S_Enable_UISeq_CustomMTClip_WithUIInteraction = UI::Checkbox("CustomMTClip_WithUIInteraction", S_Enable_UISeq_CustomMTClip_WithUIInteraction);
    UI::NextColumn();
    S_Enable_UISeq_Finish = UI::Checkbox("Finish", S_Enable_UISeq_Finish);
    UI::NextColumn();

    UI::Columns(1);
    UI::Separator();

    S_SkipNotificationWhenClanScoresGTE5 = UI::Checkbox("Skip Notification when a Team has >= 5 points (Matchmaking)", S_SkipNotificationWhenClanScoresGTE5);
    S_SkipNotificationWhenPodiumMoreRecentThanPlaying = UI::Checkbox("Skip Notification when changing maps (good for TimeAttack)", S_SkipNotificationWhenPodiumMoreRecentThanPlaying);

    UI::Separator();

    ShowWindow = UI::Checkbox("Show Debug Info", ShowWindow);
}

[Setting hidden]
bool S_SkipNotificationWhenClanScoresGTE5 = true;

[Setting hidden]
bool S_SkipNotificationWhenPodiumMoreRecentThanPlaying = true;


[SettingsTab name="UI Sequence Log" icon="ListOl" order="99"]
void Render_S_UI_Seq_Log() {
    DrawUISequenceLogTable();
}

string tmpInputStr = "Input for demo. Click to focus keyboard.";

FocusConditions DrawNotifConditionsCombo(FocusConditions curr) {
    auto ret = curr;

    if (UI::BeginCombo("Notify When?", FocusCondToStr(curr))) {
        if (UI::Selectable("Never", curr == FocusConditions::Never)) ret = FocusConditions::Never;
        if (UI::Selectable("Game Unfocused", curr == FocusConditions::GameUnfocused)) ret = FocusConditions::GameUnfocused;
        if (UI::Selectable("Keyboard (chat) has Focus", curr == FocusConditions::KeyboardHasFocus)) ret = FocusConditions::KeyboardHasFocus;
        if (UI::Selectable("Game Unfocused or Keyboard has Focus", curr == FocusConditions::GameUnfocusedOrKeyboardHasFocus)) ret = FocusConditions::GameUnfocusedOrKeyboardHasFocus;
        UI::EndCombo();
    }

    return ret;
}

string[] focusConditionStrings = {
    "Never",
    "Game Unfocused",
    "Keyboard (chat) has Focus",
    "Game Unfocused or Keyboard has Focus"
};

const string FocusCondToStr(FocusConditions fc) {
    return focusConditionStrings[fc];
}


void DrawDebugInfoGlobalState() {
    // UI::AlignTextToFramePadding();
    UI::Text("IsGameFocused: " + (IsGameFocused ? Icons::Check : Icons::Times));
    // UI::AlignTextToFramePadding();
    UI::Text("IsOpenplanetMouseOver: " + (IsOpenplanetMouseOver ? Icons::Check : Icons::Times));
    // UI::AlignTextToFramePadding();
    UI::Text("KB flag 1: IsOpenplanetKeyboardFocus: " + (IsOpenplanetKeyboardFocus ? Icons::Check : Icons::Times));
    UI::Text("KB flag 2: IsNotVehicleActionMap: " + (IsNotVehicleActionMap ? Icons::Check : Icons::Times));
    UI::Text("IsKeyboardFocus: " + (IsKeyboardFocus ? Icons::Check : Icons::Times));
    UI::Text("IsSpectatorActionMap: " + (IsSpectatorActionMap ? Icons::Check : Icons::Times));
    // UI::AlignTextToFramePadding();
    UI::Text("KeyboardInputIx: " + (KeyboardInputIx));
    UI::Text("FocusLoopActive: " + (FocusLoopActive ? Icons::Check : Icons::Times));
    UI::Text("ShouldDrawAnimations: " + (ShouldDrawAnimations ? Icons::Check : Icons::Times));
    UI::Text("activeVoice: " + (activeVoice is null ? Icons::Ban : activeVoice.IsPaused() ? Icons::Pause : Icons::Play));
}

void DrawUISequenceLogTable(bool copyAllButton = true) {
    if (copyAllButton && UI::Button(Icons::Clone + " All")) {
        string msg = "";
        for (uint i = 0; i < UISequenceEvents.Length; i++) {
            msg += UISequenceEvents[i].ToString() + "\n";
        }
        IO::SetClipboard(msg);
        Notify("Copied: " + msg);
    }
    if (UI::BeginTable("ui seq events", 6, UI::TableFlags::SizingStretchProp)) {
        auto nbEvents = UISequenceEvents.Length;
        UI::ListClipper clip(nbEvents);
        while (clip.Step()) {
            for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                auto ix = nbEvents - 1 - i;
                UISequenceEvents[ix].DrawTableRow(ix);
            }
        }
        UI::EndTable();
    }
}
