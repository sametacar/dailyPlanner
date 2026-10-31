//
//  HowItWorksView.swift
//  dailyplanner
//

import SwiftUI

/// A short, swipeable walkthrough shown on first launch (when the user has
/// no tasks yet) explaining the two core actions: creating a task and
/// dragging it onto the timeline. Also reachable anytime from Settings.
struct HowItWorksView: View {
    let onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pageCount = 3

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    finish()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            TabView(selection: $currentPage) {
                HowItWorksPage(
                    title: "howitworks.step1.title".localized,
                    subtitle: "howitworks.step1.subtitle".localized
                ) {
                    CreateTaskAnimation()
                }
                .tag(0)

                HowItWorksPage(
                    title: "howitworks.step2.title".localized,
                    subtitle: "howitworks.step2.subtitle".localized
                ) {
                    DragToTimelineAnimation()
                }
                .tag(1)

                HowItWorksPage(
                    title: "howitworks.step3.title".localized,
                    subtitle: "howitworks.step3.subtitle".localized
                ) {
                    AdjustTimeAnimation()
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            // The button itself signals whether there's a next step -
            // "Next" with a chevron on every page but the last, "Get
            // Started" only once the walkthrough is actually finished.
            Button(action: advance) {
                HStack {
                    if isLastPage {
                        Text("howitworks.button.done".localized)
                    } else {
                        Text("howitworks.button.next".localized)
                        Text("\(currentPage + 1)/\(pageCount)")
                            .opacity(0.7)
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }

    private var isLastPage: Bool {
        currentPage == pageCount - 1
    }

    private func advance() {
        if isLastPage {
            finish()
        } else {
            withAnimation {
                currentPage += 1
            }
        }
    }

    private func finish() {
        onFinish()
        dismiss()
    }
}

/// A single page of the walkthrough: a looping animated illustration above
/// a title and subtitle.
private struct HowItWorksPage<Illustration: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let illustration: Illustration

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            illustration
                .frame(height: 160)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

/// Illustrates the actual two-step flow: tap the panel icon to slide the
/// task panel open, then tap "+" to add a task. Multi-phase looping
/// animation (open panel -> pulse "+" -> new card appears -> close -> repeat)
/// so each step is shown explicitly rather than implied.
private struct CreateTaskAnimation: View {
    @State private var isIconPulsing = false
    @State private var isPanelOpen = false
    @State private var isPulsing = false
    @State private var visibleCardCount = 0
    // Identifies the current run of the loop. TabView re-fires onAppear
    // when swiping back to a page that's still alive, so without this guard
    // each return would stack another concurrent runLoop() chain on top of
    // the still-running one(s), all fighting over the same @State - that's
    // the "going crazy" glitching.
    @State private var loopID = UUID()

    // Blue, pastel red/pink, pastel green - each one added in turn, so the
    // animation shows every color actually being created, not just sitting
    // there already.
    private let cardColors = ["#85B8FF", "#FF9EB3", "#80DB9E"]
    private let hourLabels = ["07", "08", "09"]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .trailing) {
                // Mock closed timeline behind the panel - real hour rows
                // (label + divider line), matching the app's actual timeline
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        Image(systemName: "sidebar.right")
                            .font(.title3)
                            .foregroundStyle(isIconPulsing ? Color.accentColor : .secondary)
                            .scaleEffect(isIconPulsing ? 1.3 : 1.0)
                    }
                    .padding(.bottom, 8)

                    ForEach(hourLabels, id: \.self) { hour in
                        HStack(spacing: 4) {
                            Text(hour)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .frame(width: 16, alignment: .trailing)
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(width: 1)
                            Spacer()
                        }
                        .frame(height: 26)
                    }
                    Spacer()
                }
                .padding(10)
                .opacity(isPanelOpen ? 0.35 : 1)

                // Sliding task panel
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: 40, height: 8)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.green)
                            .scaleEffect(isPulsing ? 1.25 : 1.0)
                    }
                    // Each task card appears in turn as it's "added"
                    ForEach(Array(cardColors.enumerated()), id: \.offset) { index, hex in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: hex))
                            .frame(height: 22)
                            .opacity(index < visibleCardCount ? 1 : 0)
                            .scaleEffect(index < visibleCardCount ? 1 : 0.7, anchor: .leading)
                    }
                    Spacer()
                }
                .padding(10)
                .frame(width: geo.size.width * 0.58)
                .frame(maxHeight: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.12), radius: 6, x: -2, y: 2)
                .offset(x: isPanelOpen ? 0 : geo.size.width * 0.65)
            }
        }
        .frame(height: 150)
        .padding(.horizontal, 24)
        .onAppear { runLoop() }
    }

    private func runLoop() {
        let id = UUID()
        loopID = id

        // Schedules `action` after `delay`, but only runs it if this is
        // still the current loop - stale callbacks from a loop that was
        // superseded by a newer one (e.g. re-appearing after a tab swipe)
        // become harmless no-ops instead of stacking on top of the new loop.
        func after(_ delay: Double, _ action: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard loopID == id else { return }
                action()
            }
        }

        isIconPulsing = false
        isPanelOpen = false
        isPulsing = false
        visibleCardCount = 0

        // 1. The panel icon pulses first (tap indication, before anything opens)
        withAnimation(.easeInOut(duration: 0.25).repeatCount(3, autoreverses: true)) {
            isIconPulsing = true
        }
        // 2. Panel slides open
        after(0.9) {
            isIconPulsing = false
            withAnimation(.easeInOut(duration: 0.5)) {
                isPanelOpen = true
            }
        }
        // 3. Each task card is added in turn: "+" pulses, then that card
        // appears - repeated once per color, so every card is shown being
        // created rather than some just sitting there already.
        var delay: Double = 1.6
        for index in cardColors.indices {
            after(delay) {
                withAnimation(.easeInOut(duration: 0.2).repeatCount(2, autoreverses: true)) {
                    isPulsing = true
                }
            }
            after(delay + 0.5) {
                isPulsing = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    visibleCardCount = index + 1
                }
            }
            delay += 0.9
        }
        // 4. Hold, then panel closes and the loop restarts
        after(delay + 0.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isPanelOpen = false
            }
        }
        after(delay + 1.4) {
            runLoop()
        }
    }
}

/// Illustrates the real drag gesture: timeline on the LEFT, task panel on
/// the RIGHT (matching MainView's actual layout), with a card that visibly
/// travels from the panel to a timeline row - not just two cards fading
/// independently - to read as an actual drag rather than a swap.
private struct DragToTimelineAnimation: View {
    @State private var isGhostVisible = false
    @State private var ghostAtDestination = false
    @State private var isPanelCardHidden = false
    @State private var isRestingCardVisible = false
    // See CreateTaskAnimation.loopID - same fix for the same TabView
    // re-appear issue.
    @State private var loopID = UUID()

    private let cardColor = Color(hex: "#85B8FF")
    private let panelColors = ["#85B8FF", "#FF9EB3", "#80DB9E"]
    private let hourLabels = ["07", "08", "09"]

    private let timelineSize = CGSize(width: 118, height: 114)
    private let panelSize = CGSize(width: 92, height: 100)
    private let gap: CGFloat = 16

    /// Center of the first task card inside the panel (the drag's origin).
    private var dragStart: CGPoint {
        CGPoint(x: timelineSize.width + gap + panelSize.width / 2, y: 8 + 12)
    }

    /// Where the card settles - right on the boundary between the "08" and
    /// "09" rows (each hour label sits at its row's own center, so this is
    /// the exact midpoint between the two labels, not centered on either
    /// one), sitting right up against the divider line (a full drag across,
    /// not stopping short). Used for BOTH the traveling ghost's final
    /// position and the resting card, so the two line up exactly and the
    /// card never jumps on drop.
    private var dropTarget: CGPoint {
        CGPoint(x: 68, y: timelineSize.height * 2 / 3)
    }

    var body: some View {
        ZStack {
            // Mock Timeline (left): hour rows with time label + divider line
            VStack(spacing: 0) {
                ForEach(hourLabels, id: \.self) { hour in
                    HStack(spacing: 4) {
                        Text(hour)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .frame(width: 16, alignment: .trailing)
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(width: 1)
                        Spacer()
                    }
                    .frame(height: timelineSize.height / 3)
                }
            }
            .frame(width: timelineSize.width, height: timelineSize.height)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .position(x: timelineSize.width / 2, y: timelineSize.height / 2)

            // The card once it has settled into the timeline row
            RoundedRectangle(cornerRadius: 8)
                .fill(cardColor)
                .frame(width: 78, height: 26)
                .opacity(isRestingCardVisible ? 1 : 0)
                .position(dropTarget)

            // Mock Tasks panel (right): vertical list of colored task cards
            VStack(spacing: 6) {
                ForEach(Array(panelColors.enumerated()), id: \.offset) { index, hex in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: hex))
                        .frame(height: 24)
                        .opacity(index == 0 && isPanelCardHidden ? 0 : 1)
                }
            }
            .padding(8)
            .frame(width: panelSize.width, height: panelSize.height)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .position(x: timelineSize.width + gap + panelSize.width / 2, y: timelineSize.height / 2)

            // The dragged "ghost" card, traveling from the panel to the timeline
            if isGhostVisible {
                RoundedRectangle(cornerRadius: 8)
                    .fill(cardColor)
                    .frame(width: 76, height: 24)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .scaleEffect(1.06)
                    .position(ghostAtDestination ? dropTarget : dragStart)
            }
        }
        .frame(
            width: timelineSize.width + gap + panelSize.width,
            height: max(timelineSize.height, panelSize.height)
        )
        .onAppear { runLoop() }
    }

    private func runLoop() {
        let id = UUID()
        loopID = id

        func after(_ delay: Double, _ action: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard loopID == id else { return }
                action()
            }
        }

        isGhostVisible = false
        ghostAtDestination = false
        isPanelCardHidden = false
        isRestingCardVisible = false

        // 1. Pick up: the card lifts off the panel (ghost appears, panel card hides)
        after(0.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                isPanelCardHidden = true
                isGhostVisible = true
            }
        }
        // 2. Drag: the ghost travels across to the timeline row
        after(0.7) {
            withAnimation(.easeInOut(duration: 0.7)) {
                ghostAtDestination = true
            }
        }
        // 3. Drop: the ghost disappears and the card settles into place
        after(1.5) {
            isGhostVisible = false
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                isRestingCardVisible = true
            }
        }
        // 4. Reset and loop
        after(3.2) {
            runLoop()
        }
    }
}

/// Illustrates that duration is adjustable: tap the task (clock badge pops
/// in) -> a schedule sheet slides up -> its end time changes -> the card
/// itself grows to match -> sheet closes, card resets, loop - so the causal
/// link between "tap it" and "duration changes" reads clearly rather than
/// just showing a sheet in isolation.
private struct AdjustTimeAnimation: View {
    @State private var isTapped = false
    @State private var isClockVisible = false
    @State private var isSheetVisible = false
    @State private var isDurationExtended = false
    // See CreateTaskAnimation.loopID - same fix for the same TabView
    // re-appear issue.
    @State private var loopID = UUID()

    private let cardColor = Color(hex: "#85B8FF")
    private let hourLabels = ["07", "08", "09", "10"]
    private let rowHeight: CGFloat = 30
    // Text(width: 16) + HStack spacing(4) puts the divider line right at x=20,
    // so the card's leading edge sits flush against it at x=21.
    private let dividerX: CGFloat = 21
    private let timelineWidth: CGFloat = 170

    private var cardHeight: CGFloat {
        rowHeight * (isDurationExtended ? 1.5 : 1)
    }

    var body: some View {
        // .topLeading (not the default .center) so the offsets below are
        // measured from the timeline's actual top-left origin - otherwise
        // the card ends up centered-then-offset and drifts off the divider.
        ZStack(alignment: .topLeading) {
            // Mock timeline: hour rows (label + divider line)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(hourLabels, id: \.self) { hour in
                    HStack(spacing: 4) {
                        Text(hour)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .frame(width: 16, alignment: .trailing)
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(width: 1)
                        Spacer()
                    }
                    .frame(height: rowHeight)
                }
            }
            .frame(width: timelineWidth)

            // The task card, filling the "08" row flush against the divider
            // - its height grows once the end time below changes, so it
            // visibly reaches the halfway point between "09" and "10" (9:30).
            RoundedRectangle(cornerRadius: 8)
                .fill(cardColor)
                .frame(width: timelineWidth - dividerX - 8, height: cardHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(isTapped ? 0.9 : 0), lineWidth: 2)
                )
                .overlay(alignment: .topTrailing) {
                    if isClockVisible {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                            .padding(4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                // Each hour label's vertical CENTER marks its exact time
                // (see DragToTimelineAnimation.dropTarget) - not the row's
                // top edge. So "08:00" is at 1.5 rows down (row 1's center),
                // not 1 row down; starting from the row top would silently
                // begin the card at 07:30 and end it at 9:00 instead of 9:30.
                .offset(x: dividerX, y: rowHeight * 1.5)

            // Mock schedule sheet, sliding up from the bottom of the frame
            VStack {
                Spacer()
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 32, height: 4)
                        .padding(.top, 6)

                    HStack {
                        Text("Start")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("08:00")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    HStack {
                        Text("End")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(isDurationExtended ? "09:30" : "09:00")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(isDurationExtended ? Color.accentColor : .primary)
                    }
                }
                .padding(10)
                .frame(width: 132)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.15), radius: 6, y: -2)
                .offset(y: isSheetVisible ? 0 : 130)
            }
            .frame(width: timelineWidth, height: 150)
        }
        .frame(width: timelineWidth, height: 150)
        .clipped()
        .onAppear { runLoop() }
    }

    private func runLoop() {
        let id = UUID()
        loopID = id

        func after(_ delay: Double, _ action: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard loopID == id else { return }
                action()
            }
        }

        isTapped = false
        isClockVisible = false
        isSheetVisible = false
        isDurationExtended = false

        // 1. Tap the card: border highlights, clock badge pops in
        after(0.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                isTapped = true
                isClockVisible = true
            }
        }
        // 2. The schedule sheet slides up
        after(0.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isSheetVisible = true
            }
        }
        // 3. The end time changes, and the card grows to match
        after(1.7) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                isDurationExtended = true
            }
        }
        // 4. Sheet closes, card deselects
        after(2.7) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isSheetVisible = false
            }
            withAnimation(.easeOut(duration: 0.2)) {
                isTapped = false
                isClockVisible = false
            }
        }
        // 5. Reset duration and loop
        after(3.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                isDurationExtended = false
            }
        }
        after(4.0) {
            runLoop()
        }
    }
}
