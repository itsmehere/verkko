//
//  StatisticsCell.swift
//  Verkko
//
//  Created by Mihir Rao on 6/1/23.
//

import UIKit

class StatisticsCell: UITableViewCell {
    static let reuseID = "StatisticsCell"
    
    // Data
    private var statCellTitle: UILabel!
    private var statCellValue: UILabel!
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureCell() {
        // removes gray background on cell tap
        selectionStyle = .none
        
        configureStatisticsTitle()
        configureValueView()
    }
    
    private func configureStatisticsTitle() {
        let nameLabel = UILabel()
        nameLabel.text = "Err"
        nameLabel.font = .systemFont(ofSize: 14, weight: .regular)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statCellTitle = nameLabel
        addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
        ])
    }
    
    private func configureValueView() {
        let valueLabel = UILabel()
        valueLabel.text = "Err"
        valueLabel.textColor = .systemGreen
        valueLabel.font = .systemFont(ofSize: 14, weight: .bold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statCellValue = valueLabel
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
        ])
    }
    
    func set(title: String, value: String) {
        self.statCellTitle!.text = title
        self.statCellValue!.text = value
    }
}
