

class UISeqLog {
    UISeqLog@ prior = null;
    CGamePlaygroundUIConfig::EUISequence seq;
    string mode;
    uint ts = Time::Now;

    int Duration = -1;
    int MaxClanScore = 0;
    bool IsNone;
    bool IsLocal;
    bool IsMM;
    bool IsKO;
    bool InGame;

    UISeqLog(CGamePlaygroundUIConfig::EUISequence seq, const string &in mode, UISeqLog@ prior = null) {
        this.seq = seq;
        this.mode = mode;
        @this.prior = prior;
        if (UISequenceEvents.Length > 0) {
            @prior = UISequenceEvents[UISequenceEvents.Length - 1];
        }
        IsNone = seq == CGamePlaygroundUIConfig::EUISequence::None || mode.Length == 0;
        IsLocal = !IsNone && mode.Contains("_Local") && !mode.Contains("_Online");
        IsMM = !IsNone && !IsLocal && mode.Contains("Teams_Matchmaking_Online");
        IsKO = !IsNone && !IsLocal && !IsMM && mode.Contains("Knockout");
        InGame = !IsNone;
    }

    string timeStr;
    string indexStr;
    string _asString;

    void DrawTableRow(int i) {
        UI::PushID(this);

        UI::TableNextRow();
        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        indexStr = "" + i + ".";
        UI::Text(indexStr);

        UI::TableNextColumn();
        // timeStr = i < UISequenceEvents.Length - 1
        //     ? Text::Format("%.1f s", float(UISequenceEvents[i + 1].ts - ts) / 1000.)
        //     : Text::Format("%.1f s ago", float(Time::Now - ts) / 1000.);
        timeStr = Duration >= 0
            ? Text::Format("%.1f s", float(Duration) / 1000.)
            : Text::Format("%.1f s ago", float(Time::Now - ts) / 1000.);
        UI::Text(timeStr);

        UI::TableNextColumn();
        UI::Text(tostring(int(seq)));

        UI::TableNextColumn();
        UI::Text(tostring(seq));

        UI::TableNextColumn();
        UI::Text(mode);

        UI::TableNextColumn();
        _asString = "" + i + ". | " + timeStr + " | " + tostring(int(seq)) + " | " + tostring((seq)) + " | " + mode;
        if (UI::Button(Icons::Clone)) {
            IO::SetClipboard(_asString);
            Notify("Copied: " + _asString);
        }

        UI::PopID();
    }

    // only valid after being drawn at least once.
    const string ToString() {
        return _asString;
    }
}
