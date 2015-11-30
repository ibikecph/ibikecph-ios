//
//  RouteNavigationDirectionsToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

protocol RouteNavigationDirectionsToolbarDelegate {
    func didSwipeToInstruction(instruction: SMTurnInstruction, userAction: Bool)
}


class RouteNavigationDirectionsToolbarView: ToolbarView {

    var delegate: RouteNavigationDirectionsToolbarDelegate?
    
    @IBOutlet weak var topContainer: UIView!
    @IBOutlet weak var topContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var leftArrow: UIImageView!
    @IBOutlet weak var rightArrow: UIImageView!
    
    private let cellID = "TurnInstructionCellID"
    var instructions = [SMTurnInstruction]() {
        didSet {
            collectionView.contentOffset = CGPointZero // Reset scroll position
            collectionView.reloadData()
        }
    }
    var extraInstruction: SMTurnInstruction? = nil {
        didSet {
            if extraInstruction == oldValue {
                return
            }
            for subview in topContainer.subviews {
                subview.removeFromSuperview()
            }
            if let extra = extraInstruction {
                let view = TurnInstructionsCollectionViewCell()
                view.configure(extra)
                topContainer.addSubview(view)
                view.setTranslatesAutoresizingMaskIntoConstraints(false)
                self.addConstraints([
                    NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: topContainer, attribute: .Top, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: topContainer, attribute: .Left, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: view, attribute: .Right, relatedBy: .Equal, toItem: topContainer, attribute: .Right, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: topContainer, attribute: .Bottom, multiplier: 1, constant: 0)
                    ])
                topContainerHeight.constant = 100
            } else {
                topContainerHeight.constant = 0
            }
        }
    }
    private(set) var index: Int = 0 {
        didSet {
            if index == oldValue {
                return
            }
            let clipped = max(min(index, instructions.count-1), 0)
            if index != clipped {
                index = clipped
                return
            }
            delegate?.didSwipeToInstruction(instructions[index], userAction: userTouched)
            userTouched = false
            updateArrows()
        }
    }
    private var userTouched = false
    
    override func setup() {
        super.setup()
        collectionView.allowsSelection = false
        collectionView.registerClass(TurnInstructionsCollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        updateArrows()
    }
    
    override func layoutSubviews() {
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = CGSize(width: frame.width, height: collectionView.frame.height) // Update itemSize to fill entire view width
        }
        super.layoutSubviews()
    }
    
    func updateArrows() {
        let leftVisible = index != 0
        let rightVisible = index != instructions.count - 1
        leftArrow.hidden = !leftVisible
        rightArrow.hidden = !rightVisible
    }
    
    func goToIndex(index: Int, animated: Bool = true) {
        let indexPath = NSIndexPath(forItem: index, inSection: 0)
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: animated)
        // Don't set self.index directly. It will be updated via scrollDidScroll() delegate callback on UIScrollView
    }
}


extension RouteNavigationDirectionsToolbarView {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        instructions = [SMTurnInstruction]()
        collectionView.reloadData()
    }
}


extension RouteNavigationDirectionsToolbarView: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return instructions.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.cellWithIdentifier(cellID, forIndexPath: indexPath) as TurnInstructionsCollectionViewCell
        let instruction = instructions[indexPath.row]
        cell.configure(instruction)
        return cell
    }
}


extension RouteNavigationDirectionsToolbarView: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.dragging {
            userTouched = true
        }
        index = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
    }
}


extension UICollectionView {
    
    func cellWithIdentifier<T: UICollectionViewCell>(identifier: String, forIndexPath indexPath: NSIndexPath) -> T {
        if let cell = dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as? T {
            return cell
        }
        return T()
    }
}
