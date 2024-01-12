//
//  GroupAddEditLocationVC.swift
//  Verkko
//
//  Created by Justin Wong on 8/4/23.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseFirestore

class GroupAddEditLocationVC: UIViewController {
    private let mapView = MKMapView()
    private var searchController: UISearchController!
    
    private let locationManager = CLLocationManager()
    private var currentUserLocationCoordinate: CLLocationCoordinate2D?
    private var selectedTapMapAnnotation: TapMapAnnotation?
    private var searchResultsTapMapAnnotations = [TapMapAnnotation]()
    
    private var group: VKGroup!
    private var isEdit: Bool!
    private var timer = Timer()
    private let zoomOutButton = UIButton(type: .custom)
    private let addressLabel = UILabel()
    private let searchResultsLabelContainer = UIView()
    private let searchResultsCountLabel = UILabel()
    private let leftToggleButton = UIButton(type: .custom)
    private let rightToggleButton = UIButton(type: .custom)
    
    private var selectedLocationAddressViewBottomAnchor: NSLayoutConstraint?
    private let selectedLocationAddressViewBottomConstantWhenPresented: CGFloat = -60
    private let selectedLocationAddressViewBottomConstantWhenDismissed: CGFloat = 1000
    
    init(group: VKGroup, isEdit: Bool) {
        self.group = group
        self.isEdit = isEdit
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = isEdit ? "Edit Location" : "Add Location"
        view.backgroundColor = .systemBackground
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
        
        configureNavbarBlur()
        addCloseButton()
        configureMapSearchBar()
        configureMapView()
        configureSelectedLocationAddressView()
        configureSearchResultsCountLabel()
        configureToggleButtons()
        updateNavigatorButtons()
        
        selectedTapMapAnnotation = nil
        
        configureGroupLocationOnMap()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        switch traitCollection.userInterfaceStyle {
        case .light:
            searchResultsLabelContainer.backgroundColor = .white.withAlphaComponent(0.8)
        default:
            searchResultsLabelContainer.backgroundColor = .black.withAlphaComponent(0.8)
        }
    }
    
    private func configureGroupLocationOnMap() {
        if let groupLocation = group.getLocationAsCLLocationCoordinate2D() {
            selectedTapMapAnnotation = TapMapAnnotation(id: 0, coord: groupLocation)
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(selectedTapMapAnnotation!)
            mapView.selectAnnotation(selectedTapMapAnnotation!, animated: true)
            
            let currentUserRegion = MKCoordinateRegion(center: groupLocation, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            mapView.setRegion(currentUserRegion, animated: true)
            
            presentSelectedLocationAddressView()
        }
    }
    
    private func configureMapSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.tintColor = .systemGreen
        
        //Place the search bar in the navigation bar
        navigationItem.searchController = searchController
        
        //Make the search bar always visible
        navigationItem.hidesSearchBarWhenScrolling = false
        
        //Monitor when the search controller is presented and dismissed
        searchController.delegate = self

        //Monitor when the search button is tapped, and start/end editing
        searchController.searchBar.delegate = self
        
        searchController.searchBar.placeholder = "Search for a location"
        searchController.searchBar.isTranslucent = true
    }
        
    @objc private func zoomOut() {
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    private func configureMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = false
        mapView.preferredConfiguration.elevationStyle = .realistic
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        let compassButton = MKCompassButton(mapView: mapView)
        compassButton.compassVisibility = .visible
        compassButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(compassButton)
        
        let zoomOutButtonWidthHeight: CGFloat = 40
       
        zoomOutButton.setImage(UIImage(systemName: "arrow.up.backward.and.arrow.down.forward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16)), for: .normal)
        zoomOutButton.tintColor = .white
        zoomOutButton.backgroundColor = .systemGreen.withAlphaComponent(0.7)
        zoomOutButton.layer.cornerRadius = zoomOutButtonWidthHeight / 2
        zoomOutButton.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        zoomOutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(zoomOutButton)
        
        let addPinTapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addPinToMap))
        mapView.addGestureRecognizer(addPinTapGestureRecognizer)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            compassButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            compassButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            
            zoomOutButton.topAnchor.constraint(equalTo: compassButton.bottomAnchor, constant: 10),
            zoomOutButton.centerXAnchor.constraint(equalTo: compassButton.centerXAnchor),
            zoomOutButton.heightAnchor.constraint(equalToConstant: zoomOutButtonWidthHeight),
            zoomOutButton.widthAnchor.constraint(equalToConstant: zoomOutButtonWidthHeight)
        ])
    }
    
    @objc private func addPinToMap(sender: UITapGestureRecognizer) {
        switch sender.state {
        case .began:
            let touchLocation = sender.location(in: mapView)
            let locationCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            selectedTapMapAnnotation = TapMapAnnotation(id: 0, coord: locationCoordinate)
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(selectedTapMapAnnotation!)
            mapView.selectAnnotation(selectedTapMapAnnotation!, animated: true)
            
            presentSelectedLocationAddressView()
        default:
            break
        }
    }
    
    private func presentSelectedLocationAddressView() {
        Utils.getAddressFromLatLon(lat: selectedTapMapAnnotation!.coordinate.latitude, lon: selectedTapMapAnnotation!.coordinate.longitude) { result in
            switch result {
            case .success(let address):
                //Show address view
                self.addressLabel.text = address
                
                let animator = UIViewPropertyAnimator(duration: 0.8, curve: .easeIn) {
                    self.selectedLocationAddressViewBottomAnchor?.constant = self.selectedLocationAddressViewBottomConstantWhenPresented
                    self.mapView.layoutIfNeeded()
                }
                animator.startAnimation()
            case .failure(let error):
                self.presentVKAlert(title: "Cannot Fetch Location Address", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
    }
    
    private func configureSearchResultsCountLabel() {
        searchResultsLabelContainer.backgroundColor = .white.withAlphaComponent(0.8)
        searchResultsLabelContainer.layer.cornerRadius = 8
        searchResultsLabelContainer.isHidden = true
        searchResultsLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchResultsLabelContainer)
        
        searchResultsCountLabel.text = "2 Results"
        searchResultsCountLabel.textAlignment = .center
        searchResultsCountLabel.translatesAutoresizingMaskIntoConstraints = false
        searchResultsLabelContainer.addSubview(searchResultsCountLabel)
        
        NSLayoutConstraint.activate([
            searchResultsLabelContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            searchResultsLabelContainer.widthAnchor.constraint(equalToConstant: 100),
            searchResultsLabelContainer.heightAnchor.constraint(equalToConstant: 30),
            searchResultsLabelContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            searchResultsCountLabel.centerXAnchor.constraint(equalTo: searchResultsLabelContainer.centerXAnchor),
            searchResultsCountLabel.centerYAnchor.constraint(equalTo: searchResultsLabelContainer.centerYAnchor)
        ])
    }
    
    private func updateSearchResultsCountLabel(with count: Int) {
        guard count >= 0 else { return }
        searchResultsLabelContainer.isHidden = false
        searchResultsCountLabel.text = "\(count) \(count == 1 ? "Result" : "Results")"
    }
    
    //MARK: - Toggle Buttons
    private func configureToggleButtons() {
        let buttonWidthAndHeight: CGFloat = 35
        
        
        leftToggleButton.setImage(UIImage(systemName: "chevron.left.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: buttonWidthAndHeight)), for: .normal)
        leftToggleButton.tintColor = .lightGray.withAlphaComponent(0.7)
        leftToggleButton.translatesAutoresizingMaskIntoConstraints = false
        leftToggleButton.addTarget(self, action: #selector(goToLeftAnnotation), for: .touchUpInside)
        view.addSubview(leftToggleButton)
        
       
        rightToggleButton.setImage(UIImage(systemName: "chevron.right.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: buttonWidthAndHeight)), for: .normal)
        rightToggleButton.tintColor = .lightGray.withAlphaComponent(0.7)
        rightToggleButton.translatesAutoresizingMaskIntoConstraints = false
        rightToggleButton.addTarget(self, action: #selector(goToRightAnnotation), for: .touchUpInside)
        view.addSubview(rightToggleButton)
        
        NSLayoutConstraint.activate([
            leftToggleButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            leftToggleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            leftToggleButton.widthAnchor.constraint(equalToConstant: buttonWidthAndHeight),
            leftToggleButton.heightAnchor.constraint(equalToConstant: buttonWidthAndHeight),
            
            rightToggleButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            rightToggleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            rightToggleButton.widthAnchor.constraint(equalToConstant: buttonWidthAndHeight),
            rightToggleButton.heightAnchor.constraint(equalToConstant: buttonWidthAndHeight)
        ])
    }
    
    @objc private func goToLeftAnnotation() {
        guard let selectedTapMapAnnotation = selectedTapMapAnnotation else { return }
        
        if selectedTapMapAnnotation.id - 1 >= 0 {
            let leftAnnotation = searchResultsTapMapAnnotations[selectedTapMapAnnotation.id - 1]
            self.selectedTapMapAnnotation = leftAnnotation
            mapView.selectAnnotation(leftAnnotation, animated: true)
            centerMapView(annotation: leftAnnotation)
        }
        
        updateNavigatorButtons()
    }
    
    @objc private func goToRightAnnotation() {
        guard let selectedTapMapAnnotation = selectedTapMapAnnotation else { return }
        
        if selectedTapMapAnnotation.id + 1 <= searchResultsTapMapAnnotations.count - 1 {
            let rightAnnotation = searchResultsTapMapAnnotations[selectedTapMapAnnotation.id + 1]
         
            mapView.selectAnnotation(rightAnnotation, animated: true)
            centerMapView(annotation: rightAnnotation)
        }
        updateNavigatorButtons()
    }
    
    private func centerMapView(annotation: MKAnnotation) {
        let centeredRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        mapView.setRegion(centeredRegion, animated: true)
    }
    
    private func updateNavigatorButtons() {
        if searchResultsTapMapAnnotations.isEmpty {
            leftToggleButton.isHidden = true
            rightToggleButton.isHidden = true
            return
        } else {
            if selectedTapMapAnnotation == nil {
                leftToggleButton.isHidden = true
                rightToggleButton.isHidden = true
                return
            }
            
            updateLeftNavigatorButton()
            updateRightNavigatorButton()
        }
    }
    
    private func updateLeftNavigatorButton() {
        guard let selectedTapMapAnnotation = selectedTapMapAnnotation else { return }
        
        if selectedTapMapAnnotation.id - 1 >= 0 {
            leftToggleButton.isHidden = false
        } else {
            leftToggleButton.isHidden = true
        }
    }
    
    private func updateRightNavigatorButton() {
        guard let selectedTapMapAnnotation = selectedTapMapAnnotation else { return }
        
        if selectedTapMapAnnotation.id + 1 <= searchResultsTapMapAnnotations.count - 1 {
            rightToggleButton.isHidden = false
        } else {
            rightToggleButton.isHidden = true
        }
    }
    
    //MARK: - Selected Location Address View
    private func configureSelectedLocationAddressView() {
        let selectedLocationAddressView = UIView()
        selectedLocationAddressView.backgroundColor = .systemBackground
        selectedLocationAddressView.layer.shadowColor = UIColor.black.cgColor
        selectedLocationAddressView.layer.shadowRadius = 25
        selectedLocationAddressView.layer.shadowOpacity = 0.5
        selectedLocationAddressView.layer.shadowOffset = .zero
        selectedLocationAddressView.layer.cornerRadius = 16
        selectedLocationAddressView.layer.borderWidth = 1
        selectedLocationAddressView.layer.borderColor = UIColor.white.cgColor
        selectedLocationAddressView.translatesAutoresizingMaskIntoConstraints = false
        selectedLocationAddressView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(selectedLocationAddressView)
        
        addressLabel.textAlignment = .center
        addressLabel.font = .systemFont(ofSize: 17, weight: .bold)
        addressLabel.textColor = .gray
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.numberOfLines = 2
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedLocationAddressView.addSubview(addressLabel)
        
        selectedLocationAddressViewBottomAnchor = selectedLocationAddressView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: selectedLocationAddressViewBottomConstantWhenDismissed)
        selectedLocationAddressViewBottomAnchor?.isActive = true
        
        let closeButton = UIButton(type: .close)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeSelectedLocationAddressView), for: .touchUpInside)
        selectedLocationAddressView.addSubview(closeButton)
        
        let selectLocationButton = VKButton(backgroundColor: .systemGreen, title: isEdit ? "Update" : "Choose")
        selectLocationButton.addTarget(self, action: #selector(chooseLocation), for: .touchUpInside)
        selectLocationButton.translatesAutoresizingMaskIntoConstraints = false
        selectedLocationAddressView.addSubview(selectLocationButton)
        
        let padding: CGFloat = 20
        
        NSLayoutConstraint.activate([
            selectedLocationAddressView.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 30),
            selectedLocationAddressView.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -30),
            selectedLocationAddressView.heightAnchor.constraint(equalToConstant: 180),
            
            addressLabel.heightAnchor.constraint(equalToConstant: 80),
            addressLabel.leadingAnchor.constraint(equalTo: selectedLocationAddressView.leadingAnchor, constant: padding),
            addressLabel.trailingAnchor.constraint(equalTo: selectedLocationAddressView.trailingAnchor, constant: -padding),
            addressLabel.bottomAnchor.constraint(equalTo: selectLocationButton.topAnchor, constant: -5),
            
            closeButton.topAnchor.constraint(equalTo: selectedLocationAddressView.topAnchor, constant: 10),
            closeButton.leadingAnchor.constraint(equalTo: selectedLocationAddressView.leadingAnchor, constant: 10),
            
            selectLocationButton.bottomAnchor.constraint(equalTo: selectedLocationAddressView.bottomAnchor, constant: -padding),
            selectLocationButton.leadingAnchor.constraint(equalTo: selectedLocationAddressView.leadingAnchor, constant: padding),
            selectLocationButton.trailingAnchor.constraint(equalTo: selectedLocationAddressView.trailingAnchor, constant: -padding),
            selectLocationButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    @objc private func chooseLocation() {
        guard let selectedTapMapAnnotation = selectedTapMapAnnotation else { return }
        let coordinate = selectedTapMapAnnotation.coordinate
        
        FirebaseManager.shared.updateGroup(for: group.jointID, fields: [
            "location": GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        ]) { error in
            if let error = error {
                self.presentVKAlert(title: "Cannot Update Group Location", message: error.getMessage(), buttonTitle: "OK")
            } else {
                self.searchController.dismiss(animated: true)
                self.dismiss(animated: true)
            }
        }
    }
    
    @objc private func closeSelectedLocationAddressView() {
        mapView.deselectAnnotation(selectedTapMapAnnotation, animated: true)
        selectedTapMapAnnotation = nil
        updateNavigatorButtons()
        
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeOut) {
            self.selectedLocationAddressViewBottomAnchor?.constant = self.selectedLocationAddressViewBottomConstantWhenDismissed
            self.mapView.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    private func search(for searchText: String) {
        guard !searchText.isEmpty else { return }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText

        let mapSearch = MKLocalSearch(request: searchRequest)
        mapSearch.start { response, error in
            guard let response = response else {
                self.presentVKAlert(title: "Error Searching Location", message: error!.localizedDescription, buttonTitle: "OK")
                return
            }

            let tapMapAnnotations = response.mapItems.enumerated().map { index, element in
                TapMapAnnotation(id: index, coord: element.placemark.coordinate)
            }
            self.searchResultsTapMapAnnotations = tapMapAnnotations
            self.updateSearchResultsCountLabel(with: tapMapAnnotations.count)
            self.updateNavigatorButtons()
            
            if let selectedTapMapAnnotation = self.selectedTapMapAnnotation {
                self.mapView.removeAnnotation(selectedTapMapAnnotation)
                self.closeSelectedLocationAddressView()
            }
            self.mapView.addAnnotations(tapMapAnnotations)
            self.mapView.showAnnotations(tapMapAnnotations, animated: true)
            
        }
    }
}

//MARK: - CLLocationManagerDelegate
extension GroupAddEditLocationVC: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locationCoordinate = manager.location?.coordinate else { return }
        currentUserLocationCoordinate = locationCoordinate

//        let currentUserRegion = MKCoordinateRegion(center: locationCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
//        mapView.setRegion(currentUserRegion, animated: true)
    }
}

//MARK: - MKMapViewDelegate
extension GroupAddEditLocationVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? TapMapAnnotation {
            selectedTapMapAnnotation = annotation
            centerMapView(annotation: annotation)
            updateNavigatorButtons()
            presentSelectedLocationAddressView()
        }
    }
}

//MARK: - UISearchBarDelegate
extension GroupAddEditLocationVC: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            mapView.removeAnnotations(searchResultsTapMapAnnotations)
            if let selectedTapMapAnnotation = selectedTapMapAnnotation {
                mapView.showAnnotations([selectedTapMapAnnotation], animated: true)
            }
            return
        }
        
        search(for: searchText)
    }
}

//MARK: - UISearchControllerDelegate
extension GroupAddEditLocationVC: UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        mapView.removeAnnotations(searchResultsTapMapAnnotations)
        if let selectedTapMapAnnotation = selectedTapMapAnnotation {
            mapView.addAnnotation(selectedTapMapAnnotation)
        }
        
        searchResultsTapMapAnnotations.removeAll()
        closeSelectedLocationAddressView()
        searchResultsLabelContainer.isHidden = true
    }
}

