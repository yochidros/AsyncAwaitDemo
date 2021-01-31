//
//  ViewController.swift
//  AsyncAwaitDemo
//
//  Created by yochidros on 2021/01/31.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    private let userAPI = UserAPI(client: .init())
    private var items: [User] = []

    let refresh = UIRefreshControl()
    override func viewDidLoad() {
        super.viewDidLoad()
        printThread()

        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "UserTableViewCell")
        tableView.refreshControl = refresh
        refresh.beginRefreshing()

        tableView.delegate = self
        tableView.dataSource = self

        fetchSingleTask()
        fetchMultiTask()
        fetchUsersAsAsync()
        print("complete viewDidLoad")

    }
    @asyncHandler func fetchCancellation() {
        runAsyncAndBlock { [userAPI] in
            print("start")
            printThread()
            let handle: Task.Handle<[User]> = Task.runDetached {
                sleep(1)
                let isCancelAfter = await Task.isCancelled()
                print(isCancelAfter)
                return try await userAPI.fetchUsers()
            }
            do {
                let isCancelBefore = await Task.isCancelled()
                print(isCancelBefore)
                handle.cancel()
                //                try await self?.userAPI.fetchCancel() // not implement
                //                try await self?.userAPI.fetchDead() // not implemtn
                let result = try await handle.get()
                print(result)
            } catch {
                print(error)
            }

            print("end")
            printThread()
        }
    }
    // 直列
    @asyncHandler func fetchSingleTask() {
        printThread()
        print("singl task:  start")
        runAsyncAndBlock {
            printThread()
            // single tasks
            let fetchUsers1: Task.Handle<[User]> = Task.runDetached {
                sleep(2)
                print("Fetch User 1")
                let user1 = try await self.userAPI.fetchUser(id: "1")
                print("Fetch User 2")
                let user2 = try await self.userAPI.fetchUser(id: "2")
                return [user1, user2]
            }
            do {
                print("fetch start")
                let result = try await fetchUsers1.get()
                print("user: \(result)")
                print("fetch end")
            } catch {
                print(error)
            }
        }
        print("singl task:  end")
    }
    // 並列
    @asyncHandler func fetchMultiTask() {
        print("multi task:  start")
        runAsyncAndBlock {
            // multi tasks
            let fetchUsers: Task.Handle<[User]> = Task.runDetached {
                print("Fetch User 1")
                async let user1 = self.userAPI.fetchUser(id: "1")
                print("Fetch User 2")
                async let user2 = self.userAPI.fetchUser(id: "2")
                return try await [user1, user2]
            }
            do {
                print(try await fetchUsers.get())
            } catch {
                print(error)
            }
        }
        print("multi task:  end")
    }



    /// Dispatch
    func fetchAsDispatch() {
        userAPI.fetchUsersDispatch { users in
            print(users)
        } onFailure: { error in
            print(error)
        }
    }


    // non blocking
    @asyncHandler func fetchUsersAsAsync() {
        print("start async handle")
        do {
            printThread()
            let users = try await userAPI.fetchUsers()
            DispatchQueue.main.async {
                self.items = users
                self.tableView.reloadData()
                self.refresh.endRefreshing()
            }
        } catch let error {
            print(error)
        }
        print("complete async handle")
    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath)

        if let c = cell as? UserTableViewCell {
            let item = items[indexPath.row]
            c.configure(imageUrl: item.avatarUrl, name: item.name, createAt: item.createdAt)
        }
        return cell
    }
}
