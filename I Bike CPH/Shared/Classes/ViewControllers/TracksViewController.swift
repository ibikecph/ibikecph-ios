//
//  TracksViewController.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 20/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class TracksViewController: SMTranslatedViewController {

    @IBOutlet weak var tableView: UITableView!
    fileprivate var tracks: RLMResults<RLMObject>?
    fileprivate var selectedTrack: Track?
    fileprivate var observerTokens = [AnyObject]()
    
    deinit {
        unobserve()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        observerTokens.append(NotificationCenter.observe(processedSmallNoticationKey) { [weak self] notification in
            self?.updateUI()
        })
        observerTokens.append(NotificationCenter.observe(processedBigNoticationKey) { [weak self] notification in
            self?.updateUI()
        })
        observerTokens.append(NotificationCenter.observe(processedGeocodingNoticationKey) { [weak self] notification in
            self?.updateUI()
        })
        updateUI()
    }
    
    func updateUI() {
        //TODO: temp commenting out of Realm-related logic
        /*tracks = Track.allObjects().sortedResults(usingProperty: "startTimestamp", ascending: false)
        tableView.reloadData()*/
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            segue.identifier == "trackListToDetail",
            let track = selectedTrack,
            let trackDetailViewController = segue.destination as? TrackDetailViewController
        {
            trackDetailViewController.track = track
        }
    }
    
    fileprivate func unobserve() {
        for observerToken in observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    @IBAction func didTapCleanUp(_ sender: AnyObject) {
        TracksHandler.setNeedsProcessData(true)
    }
}


private let cellID = "TrackCell"

extension TracksViewController: UITableViewDataSource {
    
    func track(_ indexPath: IndexPath?) -> Track? {
        if let indexPath = indexPath {
            return tracks?[UInt(indexPath.row)] as? Track
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(tracks?.count ?? 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.cellWithIdentifier(cellID, forIndexPath: indexPath) as DebugTrackTableViewCell
        cell.updateToTrack(track(indexPath), index: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .left)
            track(indexPath)?.deleteFromRealmWithRelationships()
            tableView.endUpdates()
        }
    }
}

extension TracksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let track = track(indexPath) {
            selectedTrack = track
            performSegue(withIdentifier: "trackListToDetail", sender: self)
        }
    }
}







class DebugTrackTableViewCell: UITableViewCell {
    
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var mapView: TrackMapView!
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    func updateToTrack(_ track: Track?, index: Int = 0) {
        if let track = track {
            var title = "\(index)) "
            if let date = track.startDate() {
                title += dateFormatter.string(from: date as Date)
            }
            if let date = track.endDate() {
                title += " to " + dateFormatter.string(from: date as Date)
            }
            var subtitle = "\(track.activity.confidence)"
            if track.activity.stationary { subtitle += ",st" }
            if track.activity.cycling { subtitle += ",bk" }
            if track.activity.walking { subtitle += ",wk" }
            if track.activity.running { subtitle += ",rn" }
            if track.activity.automotive { subtitle += ",aut" }
            if track.activity.unknown { subtitle += ",un" }
            let horizontal = (track.locations.objects(with: NSPredicate(value: true)).max(ofProperty: "horizontalAccuracy") as AnyObject).int32Value ?? -1
            let vertical = (track.locations.objects(with: NSPredicate(value: true)).max(ofProperty: "verticalAccuracy") as AnyObject).int32Value ?? -1
            subtitle += "\(horizontal) \(vertical)"
            subtitle += ",\(Int(round(track.length)))m,\(Int(round(track.length)))s,\(round(track.length/1000/(track.duration/3600)))kmh"
            subtitle += ",fy:\(round(track.flightDistance() ?? 0))m"
            
            subtitle += " " + dateFormatter.string(from: track.activity.startDate as Date)
            
            fromLabel.text = title
            toLabel.text = subtitle
        }
        mapView.track = track
    }
}






import MapKit

class TrackMapView: MKMapView {
    
    var track: Track? {
        didSet {
            if let track = track {
                delegate = self
                updateToTrack(track)
            } else {
                removeOverlays(overlays)
            }
        }
    }
    
    func updateToTrack(_ track: Track) {
        removeOverlays(overlays)
        
        let overlay = polylineForLocationPoints(track.locations)
        zoomToTrack(track)
        add(overlay, level: .aboveRoads)
    }
    
    fileprivate func polylineForLocationPoints(_ locationPoints: RLMArray<RLMObject>) -> MKPolyline {
        var coordinates = coordinatesForLocationPoints(locationPoints)
        return MKPolyline(coordinates: &coordinates, count: coordinates.count)
    }
    
    fileprivate func coordinatesForLocationPoints(_ locationPoints: RLMArray<RLMObject>) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
        for rlmLocationPoint in locationPoints {
            if let locationPoint = rlmLocationPoint as? TrackLocation {
                coordinates.append(locationPoint.coordinate())
            }
        }
        return coordinates
    }
    
    fileprivate func zoomToTrack(_ track: Track) {
        
        var zoomRect: MKMapRect? = nil
        for location in track.locations
        {
            if let location = location as? TrackLocation {
                let annotationPoint = location.coordinate().mapPoint()
                let pointRect = MKMapRect(origin: annotationPoint, size: MKMapSize(width: 0, height: 0))
                if let _zoomRect = zoomRect {
                    zoomRect = MKMapRectUnion(_zoomRect, pointRect)
                } else {
                    zoomRect = pointRect
                }
            }
        }
        if let zoomRect = zoomRect {
            setVisibleMapRectPadded(zoomRect)
        }
    }
    
}

extension TrackMapView: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = Styler.tintColor()
            renderer.lineWidth = 4
            return renderer
        }
        assert(false,"Unexpected overlay!")
        return MKOverlayRenderer()
    }
}

extension MKMapRect {
    
    var center: MKMapPoint {
        return MKMapPoint(x: self.origin.x + self.size.width / 2, y: self.origin.y + self.size.height/2)
    }
    
    var minimumRect: MKMapRect {
        let currentSize = fmax(self.size.width, self.size.height)
        let size = currentSize * 1.1
        let newOrigin = MKMapPoint(x: center.x - size/2, y: center.y - size/2)
        let newSize = MKMapSize(width: size, height: size)
        return MKMapRect(origin: newOrigin, size: newSize)
    }
}

extension MKMapView {
    
    func setVisibleMapRectPadded(_ mapRect: MKMapRect) {
        let padding: CGFloat = 10
        let edgePadding = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        setVisibleMapRect(mapRect.minimumRect, edgePadding: edgePadding, animated: false)
    }
}


extension CLLocationCoordinate2D {
    
    func mapPoint() -> MKMapPoint {
        return MKMapPointForCoordinate(self)
    }
}

