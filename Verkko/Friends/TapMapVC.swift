//
//  TapMapVC.swift
//  Verkko
//
//  Created by Mihir Rao on 6/12/23.
//

import UIKit
import MapKit

class TapMapVC: UIViewController {
    
    private var tapMapView: MKMapView!
    
    private var friend: VKUser!
    private var friendInfo: VKFriendInfo!
    private var latList: [Double]!
    private var lonList: [Double]!
    
    init(friend: VKUser, withFriendInfo friendInfo: VKFriendInfo) {
        self.friend = friend
        self.friendInfo = friendInfo
        self.latList = friendInfo.tappedLocations["lat"]
        self.lonList = friendInfo.tappedLocations["lon"]
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setConfigurationForMainVC()
        configureTapMapView()
    }
    
    private func configureTapMapView() {
        tapMapView = MKMapView()
        tapMapView.preferredConfiguration.elevationStyle = .realistic
        tapMapView.delegate = self
        tapMapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tapMapView)
        
        let mostRecentLatCoord = latList[latList.count - 1]
        let mostRecentLonCoord = lonList[lonList.count - 1]
        let mostRecentCoord = CLLocationCoordinate2D(latitude: mostRecentLatCoord, longitude: mostRecentLonCoord)

        // Center map view around most recent tap location
        let centeredRegion = MKCoordinateRegion(center: mostRecentCoord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        tapMapView.setRegion(centeredRegion, animated: true)
        
        NSLayoutConstraint.activate([
            tapMapView.topAnchor.constraint(equalTo: view.topAnchor),
            tapMapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tapMapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tapMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        DispatchQueue.main.async {
            for i in 0...(self.latList.count - 1) {
                let coordinate = CLLocationCoordinate2D(latitude: self.latList[i], longitude: self.lonList[i])
                let annotation = TapMapAnnotation(id: i, coord: coordinate)
                self.tapMapView.addAnnotation(annotation)
                
                if coordinate.latitude == mostRecentCoord.latitude &&
                    coordinate.longitude == mostRecentCoord.longitude {
                    self.tapMapView.selectAnnotation(annotation, animated: true)
                }
            }
        }
    }
    
    //MARK: Nav Bar Settings
    private func configureMapNavBarSettings() {
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(goBackToPreviousViewController))
        navigationItem.leftBarButtonItem = closeButton
        
        let mapViewTitle = UILabel()
        mapViewTitle.text = "Tap Map"
        mapViewTitle.font = .systemFont(ofSize: 18, weight: .bold)
        navigationItem.titleView = mapViewTitle
    }
    
    @objc private func goBackToPreviousViewController() {
        dismiss(animated: true)
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController!.tabBar.isHidden = true;
        configureMapNavBarSettings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController!.tabBar.isHidden = false;
    }
}


//MARK: - Delegates
extension TapMapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? TapMapAnnotation {
            let identifier = "Annotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = false
            } else {
                annotationView!.annotation = annotation
            }

            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? TapMapAnnotation {
            let modal = TapMapAnnotationDialogueVC(friend: self.friend, withFriendInfo: self.friendInfo, mapView: tapMapView, annotation: annotation)
            modal.modalPresentationStyle = .overFullScreen
            modal.modalTransitionStyle = .crossDissolve
            self.present(modal, animated: true)
        }
    }
}
