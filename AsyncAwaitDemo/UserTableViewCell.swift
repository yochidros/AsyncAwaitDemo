//
//  UserTableViewCell.swift
//  AsyncAwaitDemo
//
//  Created by yochidros on 2021/01/31.
//

import UIKit

class UserTableViewCell: UITableViewCell {

    private let nameLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textAlignment = .left
        view.font = .boldSystemFont(ofSize: 16)
        return view
    }()
    private let avatarView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .gray
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(imageUrl: String, name: String, createAt: Date) {
        nameLabel.text = name
        avatarView.downloadImage(urlString: imageUrl)
    }

    override func prepareForReuse() {
        avatarView.image = nil
    }
}
