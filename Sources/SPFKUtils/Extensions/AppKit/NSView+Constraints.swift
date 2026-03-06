// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-utils

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSView {
    public func addCenteredConstraintsToSuperview(
        priority: NSLayoutConstraint.Priority = .defaultHigh,
        leadingValue: CGFloat? = nil,
        trailingValue: CGFloat? = nil
    ) {
        guard let superview else { return }

        addCenteredConstraints(
            to: superview,
            priority: priority,
            leadingValue: leadingValue,
            trailingValue: trailingValue
        )
    }

    public func addCenteredConstraints(
        to otherView: NSView,
        priority: NSLayoutConstraint.Priority = .defaultHigh,
        leadingValue: CGFloat? = nil,
        trailingValue: CGFloat? = nil
    ) {
        translatesAutoresizingMaskIntoConstraints = false

        var width: NSLayoutConstraint?
        let height = heightAnchor.constraint(equalToConstant: frame.size.height)

        let centerY = centerYAnchor.constraint(equalTo: otherView.centerYAnchor)
        var centerX: NSLayoutConstraint?

        var leading: NSLayoutConstraint?
        var trailing: NSLayoutConstraint?

        if let value = leadingValue {
            leading = leadingAnchor.constraint(equalTo: otherView.leadingAnchor, constant: value)

        } else {
            width = widthAnchor.constraint(equalToConstant: frame.size.width)
        }

        if let value = trailingValue {
            trailing = trailingAnchor.constraint(equalTo: otherView.trailingAnchor, constant: value)

        } else {
            width = widthAnchor.constraint(equalToConstant: frame.size.width)
        }

        if leading == nil && trailing == nil {
            centerX = centerXAnchor.constraint(equalTo: otherView.centerXAnchor)
        }

        let constraints: [NSLayoutConstraint] = [
            centerX, centerY, width, height, leading, trailing,
        ].compactMap { $0 }

        constraints.forEach {
            $0.priority = priority
            $0.isActive = true
        }
    }

    /// If superview exists, adds four constraints that anchor top, bottom, left and right edges of the two views.
    @objc
    open func addEqualEdgesConstraintsToSuperview(
        priority: NSLayoutConstraint.Priority = .defaultHigh,
        constant: CGFloat = 0
    ) {
        guard let superview else { return }

        addEqualEdgesConstraints(to: superview, priority: priority, constant: constant)
    }

    /// Adds four constraints that anchor top, bottom, left and right edges of two views.
    @objc
    open func addEqualEdgesConstraints(
        to otherView: NSView,
        priority: NSLayoutConstraint.Priority = .defaultHigh,
        constant: CGFloat = 0
    ) {
        addEdgeInsetConstraints(to: otherView, priority: priority, insets: NSEdgeInsets(equal: constant))
    }

    /// Adds four constraints that anchor top, bottom, left and right edges of two views.
    @objc
    open func addEdgeInsetConstraintsToSuperview(
        priority: NSLayoutConstraint.Priority = .defaultHigh,
        insets: NSEdgeInsets = .init()
    ) {
        guard let superview else { return }

        addEdgeInsetConstraints(to: superview, priority: priority, insets: insets)
    }

    public func addEdgeInsetConstraintsToSuperview(
        priorities: SuperviewConstraintPriorities,
        insets: NSEdgeInsets = .init()
    ) {
        guard let superview else { return }

        addEdgeInsetConstraints(to: superview, priorities: priorities, insets: insets)
    }

    @objc
    open func addEdgeInsetConstraints(
        to otherView: NSView,
        priority: NSLayoutConstraint.Priority = .defaultHigh,
        insets: NSEdgeInsets = .init()
    ) {
        addEdgeInsetConstraints(
            to: otherView,
            priorities: SuperviewConstraintPriorities(equalTo: priority.rawValue),
            insets: insets
        )
    }

    /// Adds four constraints that anchor top, bottom, left and right edges of two views.
    public func addEdgeInsetConstraints(
        to otherView: NSView,
        priorities: SuperviewConstraintPriorities? = nil,
        insets: NSEdgeInsets = .init()
    ) {
        translatesAutoresizingMaskIntoConstraints = false

        let leading = leadingAnchor.constraint(equalTo: otherView.leadingAnchor, constant: insets.left)
        let trailing = trailingAnchor.constraint(equalTo: otherView.trailingAnchor, constant: -insets.right)
        let top = topAnchor.constraint(equalTo: otherView.topAnchor, constant: insets.top)
        let bottom = bottomAnchor.constraint(equalTo: otherView.bottomAnchor, constant: -insets.bottom)

        let constraints = [leading, trailing, top, bottom]

        let priorities = priorities ?? SuperviewConstraintPriorities()
        let prioritiesValue = [priorities.leading, priorities.trailing, priorities.top, priorities.bottom]

        for i in 0 ..< constraints.count {
            constraints[i].priority = NSLayoutConstraint.Priority(rawValue: prioritiesValue[i])
            constraints[i].isActive = true
        }
    }

    public func addTopEdgeContraintsToSuperview(
        leadingValue: CGFloat? = nil,
        trailingValue: CGFloat? = nil,
        topValue: CGFloat = 0,
        priority: NSLayoutConstraint.Priority = .defaultHigh
    ) {
        guard let superview else { return }

        addTopEdgeContraints(
            to: superview,
            leadingValue: leadingValue,
            trailingValue: trailingValue,
            topValue: topValue,
            priority: priority
        )
    }

    public func addTopEdgeContraints(
        to otherView: NSView,
        leadingValue: CGFloat? = nil,
        trailingValue: CGFloat? = nil,
        topValue: CGFloat = 0,
        priority: NSLayoutConstraint.Priority = .defaultHigh
    ) {
        translatesAutoresizingMaskIntoConstraints = false

        var leading: NSLayoutConstraint?
        var trailing: NSLayoutConstraint?
        var width: NSLayoutConstraint?
        var centerX: NSLayoutConstraint?

        if let leadingValue {
            leading = leadingAnchor.constraint(equalTo: otherView.leadingAnchor,
                                               constant: leadingValue)
        }

        if let trailingValue {
            trailing = trailingAnchor.constraint(equalTo: otherView.trailingAnchor,
                                                 constant: -trailingValue)
        }

        let top = topAnchor.constraint(equalTo: otherView.topAnchor,
                                       constant: topValue)

        if leading == nil || trailing == nil {
            width = widthAnchor.constraint(equalToConstant: frame.size.width)
        }

        if leading == nil && trailing == nil {
            // center
            centerX = centerXAnchor.constraint(equalTo: otherView.centerXAnchor)
        }

        let height = heightAnchor.constraint(equalToConstant: frame.size.height)

        let constraints = [
            leading, trailing, top, width, height, centerX,
        ].compactMap { $0 }

        constraints.forEach {
            $0.priority = priority
            $0.isActive = true
        }
    }

    public func addBottomEdgeContraintsToSuperview(
        leadingValue: CGFloat? = nil,
        trailingValue: CGFloat? = nil,
        bottomValue: CGFloat = 0,
        priority: NSLayoutConstraint.Priority = .defaultHigh
    ) {
        guard let superview else { return }

        addBottomEdgeContraints(
            to: superview,
            leadingValue: leadingValue,
            trailingValue: trailingValue,
            bottomValue: bottomValue,
            priority: priority
        )
    }

    public func addBottomEdgeContraints(
        to otherView: NSView,
        leadingValue: CGFloat? = nil,
        trailingValue: CGFloat? = nil,
        bottomValue: CGFloat = 0,
        priority: NSLayoutConstraint.Priority = .defaultHigh
    ) {
        translatesAutoresizingMaskIntoConstraints = false

        var leading: NSLayoutConstraint?
        var trailing: NSLayoutConstraint?
        var width: NSLayoutConstraint?
        var centerX: NSLayoutConstraint?

        if let leadingValue {
            leading = leadingAnchor.constraint(
                equalTo: otherView.leadingAnchor,
                constant: leadingValue
            )
        }

        if let trailingValue {
            trailing = trailingAnchor.constraint(
                equalTo: otherView.trailingAnchor,
                constant: -trailingValue
            )
        }

        let bottom = bottomAnchor.constraint(
            equalTo: otherView.bottomAnchor,
            constant: -bottomValue
        )

        if leading == nil || trailing == nil {
            width = widthAnchor.constraint(equalToConstant: frame.size.width)
        }

        if leading == nil && trailing == nil {
            // center
            centerX = centerXAnchor.constraint(equalTo: otherView.centerXAnchor)
        }

        let height = heightAnchor.constraint(equalToConstant: frame.size.height)

        let constraints = [
            leading, trailing, bottom, width, height, centerX,
        ].compactMap { $0 }

        constraints.forEach {
            $0.priority = priority
            $0.isActive = true
        }
    }

    @objc
    open func removeAllConstraints() {
        removeConstraints(constraints)
    }

    @objc
    open func removeSuperviewConstraints() {
        guard let superview else { return }

        let superviewConstraints = superview.constraints.filter {
            $0.firstAnchor == leadingAnchor ||
                $0.firstAnchor == trailingAnchor ||
                $0.firstAnchor == topAnchor ||
                $0.firstAnchor == bottomAnchor
        }

        superview.removeConstraints(superviewConstraints)
    }
}

public struct SuperviewConstraintPriorities: Sendable {
    public static let defaultHigh = SuperviewConstraintPriorities(equalTo: defaultValue)

    public static let defaultValue: Float = NSLayoutConstraint.Priority.defaultHigh.rawValue

    public let leading: Float
    public let trailing: Float
    public let top: Float
    public let bottom: Float

    public init(equalTo value: Float) {
        leading = value
        trailing = value
        top = value
        bottom = value
    }

    public init(leading: Float = Self.defaultValue,
                trailing: Float = Self.defaultValue,
                top: Float = Self.defaultValue,
                bottom: Float = Self.defaultValue) {
        self.leading = leading
        self.trailing = trailing
        self.top = top
        self.bottom = bottom
    }
}
#endif
