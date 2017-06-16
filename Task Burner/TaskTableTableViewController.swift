//
//  TaskTableTableViewController.swift
//  Task Burner
//
//  Created by Felix Vandelanotte on 16/06/2017.
//  Copyright © 2017 Felix Vandelanotte. All rights reserved.
//

import UIKit
import Firebase

class TasksTableViewController: UITableViewController {
    
    static let kTasksListPath = "tasks-list"
    static let kTaskViewControllerSegueIdentifier = "TaskViewController"
    
    let tasksReference = FIRDatabase.database().reference(withPath: kTasksListPath)
    var tasks = [Task]()
    var selectedTask: Task? = nil
    weak var currentUser = FIRAuth.auth()?.currentUser
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Query tasks from firebase when this view controller is instantiated
         */
        self.tasksReference.queryOrdered(byChild: Task.kTaskCompletedKey).observe(.value, with: { snapshot in
            
            /* The callback block will be executed each and every time the value changes.
             */
            var items: [Task] = []
            
            for item in snapshot.children {
                let task = Task(snapshot: item as! FIRDataSnapshot)
                items.append(task)
            }
            
            self.tasks = items
            self.tableView.reloadData()
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == TasksTableViewController.kTaskViewControllerSegueIdentifier {
            /* Pass along the selected task to the particular task view controller.
             */
            if let taskViewController = segue.destination as? TaskViewController {
                taskViewController.taskTitle = self.selectedTask?.title
                taskViewController.taskCompleted = self.selectedTask?.completed
            }
        }
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        if let taskViewController = segue.source as? TaskViewController {
            taskViewController.updateValues()
            
            if let task = self.selectedTask {
                /* This particular task was an existing one
                 it should be updated in Firebase.
                 */
                if let title = taskViewController.taskTitle,
                    let completed = taskViewController.taskCompleted,
                    let email = self.currentUser?.email {
                    
                    let taskFirebasePath = task.firebaseReference
                    taskFirebasePath?.updateChildValues([
                        Task.kTaskTitleKey: title,
                        Task.kTaskUserKey: email,
                        Task.kTaskCompletedKey: completed
                        ])
                }
            } else {
                /* This task is new,
                 it should be created in Firebase
                 */
                if let title = taskViewController.taskTitle,
                    let completed = taskViewController.taskCompleted,
                    let email = self.currentUser?.email {
                    
                    let task = Task(title: title, user: email, completed: completed)
                    let taskFirebasePath = self.tasksReference.ref.child(title.lowercased())
                    taskFirebasePath.setValue(task.toDictionary())
                }
            }
        }
        self.selectedTask = nil
    }
    
    @IBAction func addTask() {
        self.performSegue(withIdentifier: TasksTableViewController.kTaskViewControllerSegueIdentifier, sender: self)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tasks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksTableViewCell", for: indexPath)
        
        if let c = cell as? TasksTableViewCell {
            let task = self.tasks[indexPath.row]
            c.titleLabel.text = task.title
            c.completedSwitch.setOn(task.completed, animated: true)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = self.tasks[indexPath.row]
        
        /* Keep a reference to the task that is currently edited.
         */
        self.selectedTask = task
        self.performSegue(withIdentifier: TasksTableViewController.kTaskViewControllerSegueIdentifier, sender: self)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let task = self.tasks[indexPath.row]
            /* Delete this task.
             No tableview updates should be done here because a callback notification
             will be provided.
             */
            task.firebaseReference?.removeValue()
        }
    }
}
