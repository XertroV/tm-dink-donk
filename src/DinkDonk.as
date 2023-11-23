// call once per frame
void DinkDonkUpdate() {
    CheckUISeq();
}

UISeqLog@[] UISequenceEvents;
UISeqLog@ mostRecentSeq;

// sequence as ix -> timestamp. used to compare which UI sequence happened most recently (e.g., Alert on UI interaction if Playing happened more recently than Podium)
uint[] sequenceLastActive = array<uint>(12);
bool lastEnabled = false;
bool lastMetUISeqSettings = false;

void CheckUISeq() {
    auto cmap = GetApp().Network.ClientManiaAppPlayground;
    auto pgish = cast<CSmArenaInterfaceManialinkScripHandler>(GetApp().Network.PlaygroundInterfaceScriptHandler);
    CGamePlaygroundUIConfig::EUISequence seq = CGamePlaygroundUIConfig::EUISequence::None;
    if (cmap !is null && cmap.UI !is null) seq = cmap.UI.UISequence;
    if (lastEnabled != S_Enabled || UISequenceEvents.Length == 0 || mostRecentSeq.seq != seq || lastMetUISeqSettings != mostRecentSeq.MatchesUiSequenceSettings()) {
        lastEnabled = S_Enabled;
        if (mostRecentSeq !is null)
            mostRecentSeq.Duration = Time::Now - mostRecentSeq.ts;
        @mostRecentSeq = UISeqLog(seq, cast<CTrackManiaNetworkServerInfo>(GetApp().Network.ServerInfo).ModeName, mostRecentSeq);
        mostRecentSeq.MaxClanScore = pgish.ClanScores.Length < 3 ? 0 : Math::Max(pgish.ClanScores[1], pgish.ClanScores[0]);
        UISequenceEvents.InsertLast(mostRecentSeq);
        sequenceLastActive[seq] = Time::Now;
        lastMetUISeqSettings = mostRecentSeq.MatchesUiSequenceSettings();
        CheckShouldNotify();
    }
}


/**
 * When to play?
 *
 * UIInteraction when last UISeq is not podium (or playing was more recent than podium)
 * EndRound in MM
 * -- unless a player
 *
 * Never in playmap local / campaign
 * -- players always > 1
 *
 * TM_Teams_Matchmaking_Online -- EndRound
 * TM_Knockout_Online (and variants) -- UIInteraction
 * TM_Cup_Online -- EndRound
 *
 */

void CheckShouldNotify() {
    if (mostRecentSeq.IsLocal || !S_Enabled) return;

    auto @prior = mostRecentSeq.prior;

    startnew(MonitorFocusLoop);
}

bool ShouldDrawAnimations = false;
bool FocusLoopActive = false;

void MonitorFocusLoop() {
    while (FocusLoopActive) yield();
    FocusLoopActive = true;
    auto seq = mostRecentSeq.seq;
    // if (!mostRecentSeq.MatchesUiSequenceSettings()) {
    //     NotifyWarning("Monitor focus loop got an unexpected ui sequence: " + tostring(seq));
    //     FocusLoopActive = false;
    //     return;
    // }

    while (seq == mostRecentSeq.seq) {
        ShouldDrawAnimations = !IsGameFocused || IsKeyboardFocus;
        ShouldDrawAnimations = ShouldDrawAnimations && mostRecentSeq.MatchesUiSequenceSettings();
        if (CurrentlyMeetsFocusNotificationConditions()) {
            // sound should play
            EnsureNotifSoundPlaying();
        } else {
            // sound should not play
            EnsureNotifSoundNotPlaying();
        }
        if (!mostRecentSeq.MatchesUiSequenceSettings()) break;
        yield();
    }
    ShouldDrawAnimations = false;
    FocusLoopActive = false;
    EnsureNotifSoundNotPlaying();
}


// true if it's okay to proceed
bool CurrentlyMeetsSkipSettings() {
    if (S_SkipNotificationWhenClanScoresGTE5 && mostRecentSeq.MaxClanScore >= 5) return false;
    if (S_SkipNotificationBetweenMaps && (IsPodiumMoreRecentThanPlaying() || IsLoadingScreen())) return false;
    return true;
}


bool CurrentlyMeetsFocusNotificationConditions() {
    if (!CurrentlyMeetsSkipSettings()) return false;
    if (!mostRecentSeq.MatchesUiSequenceSettings()) return false;

    bool isEither = S_RoundStartNotifConditions == FocusConditions::GameUnfocusedOrKeyboardHasFocus;

    return (!IsGameFocused && (S_RoundStartNotifConditions == FocusConditions::GameUnfocused || isEither))
        || (IsKeyboardFocus && (S_RoundStartNotifConditions == FocusConditions::KeyboardHasFocus || isEither))
        || (S_RoundStartNotifConditions == FocusConditions::Always)
        ;
}

bool IsPodiumMoreRecentThanPlaying() {
    auto last = sequenceLastActive[CGamePlaygroundUIConfig::EUISequence::Podium];
    return last > 0 && last > sequenceLastActive[CGamePlaygroundUIConfig::EUISequence::Playing];
}

bool IsNoneMoreRecentThanPlaying() {
    auto last = sequenceLastActive[CGamePlaygroundUIConfig::EUISequence::None];
    return last > 0 && last > sequenceLastActive[CGamePlaygroundUIConfig::EUISequence::Playing];
}

bool IsLoadingScreen() {
    auto lp = GetApp().LoadProgress;
    return lp !is null && lp.State == NGameLoadProgress::EState::Displayed;
}

Audio::Voice@ activeVoice = null;
uint lastActiveVoiceStart = 0;
uint soundDuration = 2100;

void EnsureNotifSoundPlaying() {
    if (activeVoice !is null && Time::Now - soundDuration < lastActiveVoiceStart) {
        return;
    }
    @activeVoice = Audio::Play(KOSound, S_Gain);
    lastActiveVoiceStart = Time::Now;
    startnew(CleanUpSoundLater);
}

void CleanUpSoundLater() {
    uint startedAt = lastActiveVoiceStart;
    sleep(soundDuration);
    // if no new voice has been started
    if (startedAt == lastActiveVoiceStart) {
        EnsureNotifSoundNotPlaying();
    }
}

void EnsureNotifSoundNotPlaying() {
    if (activeVoice !is null) {
        activeVoice.SetGain(0.0);
        @activeVoice = null;
    }
    lastActiveVoiceStart = 0;
}


vec2 screen, mainTL, mainPivot, mainSize, armTL, armPivot, armSize, ddScale;

vec2 mainNative = vec2(83, 84), armNative = vec2(43, 57);
mat3 armRot;
// 0.0 or 1.0 depending on the frame
float frameOddEven = 0.0;
float frameOddEvenSlower = 0.0;
float frameNumber = 0;
float angle;

void UpdateRenderVars() {
    screen.x = Draw::GetWidth();
    screen.y = Draw::GetHeight();

    mainSize = vec2(.333, .333) * screen.y;
    mainTL = screen / 2. - mainSize / 2.;
    mainPivot = mainTL + mainSize * vec2(73.7, 73.7) / mainNative;

    ddScale = mainSize / mainNative;

    UpdateRenderArmVars();
}


void UpdateRenderVarsForMenu(vec4 rect) {
    screen.x = Draw::GetWidth();
    screen.y = Draw::GetHeight();

    // auto fp = UI::GetStyleVarVec2(UI::StyleVar::FramePadding);

    auto sq = vec2(rect.w, rect.w);
    mainSize = sq * .76;
    mainTL = vec2(rect.x, rect.y) + sq * vec2(.25, .10);
    mainPivot = mainTL + mainSize * vec2(73.7, 73.7) / mainNative;

    ddScale = mainSize / mainNative;

    UpdateRenderArmVars(true);
}

void UpdateRenderArmVars(bool isMenuIcon = false) {
    armPivot = vec2(5.5, 51.8) * ddScale;
    frameNumber = float(Time::Now) / float(dynamicPeriodMs);
    frameOddEven = Math::Abs((frameNumber / 2. - Math::Floor(frameNumber / 2.)) * 2. - 1.);
    frameOddEvenSlower = Math::Abs((frameNumber / 12. - Math::Floor(frameNumber / 12.)) * 2. - 1.);
    // frameOddEven = Math::Abs(float(frameNumber % 3) - 1);
    angle = frameOddEven * Math::ToRad(-24.0) + Math::ToRad(1);
    if (isMenuIcon && S_DisableMenuIconAnimation) angle = 0.;

    armRot = mat3::Translate(mainPivot - armPivot) * mat3::Translate(armPivot) * mat3::Rotate(angle) * mat3::Translate(armPivot * -1);
    armTL = (armRot * vec2(0, 0)).xy;
    armSize = armNative * ddScale;
}

// call immediately after drawing menu item
void DrawDinkDonkForMenu() {
    UpdateRenderVarsForMenu(UI::GetItemRect());
    _DrawDinkDonkImage(UI::GetWindowDrawList());
}

void _DrawDinkDonkImage(UI::DrawList@ dl) {
    // dl.PushClipRect(vec4(mainTL.x, mainTL.y, mainSize.x, mainSize.y));
    dl.AddImage(DDMainTex, mainTL, mainSize, 0xFFFFFFFF, 0.0);
    dl.AddImage(DDArmTex, armTL, armSize, 0xFFFFFFFF, angle);
    // dl.PopClipRect();
}

void RenderDinkDonk() {
    if (!CurrentlyMeetsSkipSettings()) return;
    UpdateRenderVars();
    if (S_DrawDinkDonkImage)
        _DrawDinkDonkImage(UI::GetForegroundDrawList());

    if (S_DrawFocusedWarningText) {
        if (!IsGameFocused) {
            DrawDDText("GAME NOT FOCUSED");
        } else if (IsKeyboardFocus) {
            DrawDDText(Icons::Heartbeat + " / " + Icons::KeyboardO + " FOCUSED");
        }
    }
}

int g_NvgFont = nvg::LoadFont("DroidSans.ttf", true);

void DrawDDText(const string &in text) {
    nvg::Reset();
    nvg::BeginPath();
    auto fs = screen.y * 0.07;
    nvg::FontSize(fs);
    nvg::FontFace(g_NvgFont);

    auto bounds = nvg::TextBounds(text);
    auto topPos = vec2(screen.x / 2. - bounds.x / 2., mainTL.y - fs / 4.);
    auto botPos = vec2(screen.x / 2. - bounds.x / 2., mainTL.y + mainSize.y + fs);

    // nvg::FillColor();
    vec4 textCol = Math::Lerp(vec4(.3, 1, .3, 1), vec4(1, 1, .3, 1), frameOddEvenSlower);

    DrawTextWithStroke(topPos, text, textCol, fs * 0.1);
    DrawTextWithStroke(botPos, text, textCol, fs * 0.1);

    nvg::ClosePath();
}

const float TAU = 6.28318530717958647692;
// this does not seem to be expensive
const float nTextStrokeCopies = 32;

void DrawTextWithStroke(const vec2 &in pos, const string &in text, vec4 textColor, float strokeWidth, vec4 strokeColor = vec4(0, 0, 0, 1)) {
    nvg::FillColor(strokeColor);
    for (float i = 0; i < nTextStrokeCopies; i++) {
        float angle = TAU * float(i) / nTextStrokeCopies;
        vec2 offs = vec2(Math::Sin(angle), Math::Cos(angle)) * strokeWidth;
        nvg::Text(pos + offs, text);
    }
    nvg::FillColor(textColor);
    nvg::Text(pos, text);
}
