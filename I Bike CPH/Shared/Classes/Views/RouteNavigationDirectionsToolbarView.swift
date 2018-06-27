//
//  RouteNavigationDirectionsToolbarView.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/06/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

protocol RouteNavigationDirectionsToolbarDelegate {
    func didSwipeToInstruction(_ instruction: SMTurnInstruction, userAction: Bool)
}


class RouteNavigationDirectionsToolbarView: ToolbarView {

    var delegate: RouteNavigationDirectionsToolbarDelegate?
    
    @IBOutlet weak var topContainer: UIView!
    @IBOutlet weak var topContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var leftArrow: UIImageView!
    @IBOutlet weak var rightArrow: UIImageView!
    
    fileprivate let cellID = "TurnInstructionCellID"
    var instructions = [SMTurnInstruction]() {
        didSet {
            collectionView.contentOffset = CGPoint.zero // Reset scroll position
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
                view.translatesAutoresizingMaskIntoConstraints = false
                self.addConstraints([
                    NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: topContainer, attribute: .top, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: topContainer, attribute: .left, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal, toItem: topContainer, attribute: .right, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: topContainer, attribute: .bottom, multiplier: 1, constant: 0)
                    ])
                topContainerHeight.constant = 100
            } else {
                topContainerHeight.constant = 0
            }
        }
    }
    fileprivate(set) var index: Int = 0 {
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
    fileprivate var userTouched = false
    
    override func setup() {
        super.setup()
        collectionView.allowsSelection = false
        collectionView.register(TurnInstructionsCollectionViewCell.self, forCellWithReuseIdentifier: cellID)
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
        leftArrow.isHidden = !leftVisible
        rightArrow.isHidden = !rightVisible
    }
    
    func goToIndex(_ index: Int, animated: Bool = true) {
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .left, animated: animated)
        // Don't set self.index directly. It will be updated via scrollDidScroll() delegate callback on UIScrollView
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        instructions = [SMTurnInstruction]()
        collectionView.reloadData()
    }
}




extension RouteNavigationDirectionsToolbarView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return instructions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.cellWithIdentifier(cellID, forIndexPath: indexPath) as TurnInstructionsCollectionViewCell
        let instruction = instructions[indexPath.row]
        cell.configure(instruction)
        return cell
    }
}


extension RouteNavigationDirectionsToolbarView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            userTouched = true
        }
        index = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
    }
}


extension UICollectionView {
    
    func cellWithIdentifier<T: UICollectionViewCell>(_ identifier: String, forIndexPath indexPath: IndexPath) -> T {
        if let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? T {
            return cell
        }
        return T()
    }
}
