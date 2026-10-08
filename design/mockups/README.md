# Wudget Hi-Fi Mockups

Interactive HTML mockups for sprint planning and implementation guidance.

## Must-Have Mockups

### 1. [Onboarding Flow](onboarding-mockup.html)
**Sprint 10** - First-time user guidance

**Screens:**
- Welcome screen with app value proposition
- Capture flow introduction (3-tap speed)
- Tab navigation explanation (Catat, Pantau, Atur)
- Period concept introduction
- Privacy reassurance

**Key design decisions:**
- Warm local personality (not generic fintech)
- Clear visual hierarchy with emoji icons
- Skip option for returning users
- Progress indicator (1/4, 2/4, etc.)

---

### 2. [Goals & Motivation](goals-mockup.html)
**Sprint 12** - Saving goals with surplus sweep

**Features:**
- Goal creation flow (name, target amount, deadline)
- Milestone chips (25%, 50%, 75%, 100%)
- Surplus sweep toggle (auto-allocate excess to goals)
- Goal progress visualization
- Celebration states

**Key design decisions:**
- Milestone chips as visual progress markers
- Surplus sweep as opt-in feature
- Clear separation between active and completed goals
- Emoji-based goal categories

---

### 3. [Household Sharing](household-sharing-mockup.html)
**Sprint 16-17 (v2)** - Family/couple finance sharing

**Features:**
- Coming soon placeholder screen
- Feature preview (sync transactions, split bills, shared budgets)
- Email signup form for early access
- Privacy reassurance (data stays local)

**Key design decisions:**
- "Coming soon" framing to manage expectations
- Email capture for validation
- Clear privacy messaging (no data sent to server)
- Family emoji icon (warm, not corporate)

---

## Should-Have Mockups

### 4. [Capture Flow Improvements](capture-flow-mockup.html)
**Sprint 4** - Enhanced capture experience

**New features:**
- **Wallet selector chip** - Shows active wallet with balance, allows quick switching
- **Sering (Frequent) templates row** - Horizontal scroll of common transactions
- **Collapsible note field** - Reduces clutter, expands on tap

**Key design decisions:**
- Wallet chip positioned below amount display (visible but not dominant)
- Sering templates as horizontal scroll (space-efficient)
- Note field hidden by default (reduces cognitive load)
- All interactions maintain 3-tap capture speed

---

### 5. [Pantau Skeleton Loading](pantau-skeleton-mockup.html)
**Sprint 6** - Better loading states

**Features:**
- Skeleton placeholders matching actual layout
- Shimmer animation (not spinner)
- Smooth transition to loaded state
- Auto-toggle demo (every 3 seconds)

**Key design decisions:**
- Skeleton shapes match real content (pace ring, forecast card, category list)
- Shimmer animation indicates loading without blocking
- No layout shift when content loads
- Toggle button for demo purposes

---

### 6. [Split Transactions](split-transaction-mockup.html)
**Sprint 14** - Multi-category expense splitting

**Features:**
- Add multiple categories to single transaction
- Live remainder calculation
- Visual progress bar (allocated vs total)
- Category picker modal
- Validation (must balance to zero)

**Key design decisions:**
- Remainder display always visible (prevents errors)
- Progress bar changes color (blue = partial, green = complete, red = over)
- Save button disabled until balanced
- Each split item has optional note field

---

## How to Use

1. Open any `.html` file in a browser
2. Interact with buttons and inputs to see states
3. Use toggle buttons to switch between loading/loaded states
4. Review design decisions in comments

## Implementation Notes

- All mockups use wudget's design tokens (colors, spacing, typography)
- Responsive (390px width, mobile-first)
- Interactive elements are clickable
- Animations are CSS-based (no external libraries)
- Indonesian language (matches app locale)

## Next Steps

1. Review mockups with stakeholders
2. Adjust based on feedback
3. Begin implementation following sprint plan
4. Update mockups if design changes during development
