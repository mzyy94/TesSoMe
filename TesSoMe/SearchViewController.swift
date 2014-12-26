//
//  SearchViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/03.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class SearchValue: NSObject {
	enum SearchTarget {
		case User, Post, Reply, Hashtag
	}
	
	let formatString: [SearchTarget: String] = [
		.User: NSLocalizedString("Go to user \"%@\"", comment: "Search user format"),
		.Post: NSLocalizedString("Post by \"%@\"", comment: "Search post format"),
		.Reply: NSLocalizedString("Reply to @%@", comment: "Search reply format"),
		.Hashtag: NSLocalizedString("Hashtag #%@", comment: "Search hashtag format")
	]
	
	var target: SearchTarget
	var words: [String] = []
	var formatedString: String

	init(target t: SearchTarget, words w: String) {
		target = t
		words.append(w)
		formatedString = NSString(format: formatString[t]!, w)
	}
	
	class func matchUsernameFormat(string: String) -> Bool {
		return string.rangeOfString("^@?[0-9a-z]{1,16}$", options: .RegularExpressionSearch) != nil
	}
	
	class func matchHashtagFormat(string: String) -> Bool {
		return string.rangeOfString("^#?[0-9a-zA-Z]{1,1023}$", options: .RegularExpressionSearch) != nil
	}
	
	func setSearchValue(inout resultView: SearchResultViewController, withType type: TesSoMeSearchType) {
		switch target {
		case .Post:
			resultView.username = words.first
		case .Reply:
			resultView.tag = "at_\(words.first!)"
		case .Hashtag:
			resultView.tag = "hash_\(words.first!)"
		default:
			return
		}
		
		resultView.type = type
	}

}

class SearchViewController: UITableViewController, UISearchBarDelegate {

	var searchBookmark: [String] = []
	var searchWords: [SearchValue] = []

	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var searchTypeSegmentedControl: UISegmentedControl!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.searchBar.delegate = self
		
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
		let inputAccessoryView = UIToolbar()
		inputAccessoryView.barStyle = .Default
		inputAccessoryView.sizeToFit()
		let spacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
		let doneBtn = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("closeKeyboard"))
		let toolBarItems:[UIBarButtonItem] = [spacer, doneBtn]
		inputAccessoryView.setItems(toolBarItems, animated: true)
		self.searchBar.inputAccessoryView = inputAccessoryView
    }
	
	func closeKeyboard() {
		self.searchBar.endEditing(true)
	}

	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		let searchWords = searchText.componentsSeparatedByString(" ")

		switch searchWords.count {
		case 0:
			self.searchWords.removeAll(keepCapacity: true)
		case 1:
			self.searchWords.removeAll(keepCapacity: true)
			if let searchWord = searchWords.first {
				if SearchValue.matchUsernameFormat(searchWord) {
					self.searchWords.append(SearchValue(target: .User, words: searchWord))
					self.searchWords.append(SearchValue(target: .Post, words: searchWord))
					self.searchWords.append(SearchValue(target: .Reply, words: searchWord))
				}
				
				if SearchValue.matchHashtagFormat(searchWord) {
					self.searchWords.append(SearchValue(target: .Hashtag, words: searchWord))
				}
			}
		default:
			return
		}
		
		self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .None)
	}
	
	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
		switch section {
		case 0:
			return searchWords.count
		default:
			return searchBookmark.count
		}
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("SearchBtnCell", forIndexPath: indexPath) as UITableViewCell
		switch indexPath.section {
		case 0:
			let searchValue = searchWords[indexPath.row]
			cell.textLabel?.text = searchValue.formatedString
			return cell
		default:
			return cell
		}
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return indexPath.section == 1
    }
	
	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return nil
	}
	
	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 0 {
			return 0.0
		}
		return 44.0
	}
	
	override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 0.0
	}

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 1 {
			return NSLocalizedString("Bookmark", comment: "Bookmark")
		}
		return nil
	}
	
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView!, moveRowAtIndexPath fromIndexPath: NSIndexPath!, toIndexPath: NSIndexPath!) {

    }
    */

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if searchWords[indexPath.row].target == .User {
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let userViewController = storyboard.instantiateViewControllerWithIdentifier("UserView") as UserViewController
			userViewController.username = searchWords[indexPath.row].words.first!
			
			self.navigationController?.pushViewController(userViewController, animated: true)
            closeKeyboard()
        }
    }
	
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }

	override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
		let indexPath = tableView.indexPathForCell(sender as UITableViewCell)!
		if searchWords[indexPath.row].target == .User {
			return false
		}
		return true
	}
	
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
		let indexPath = tableView.indexPathForCell(sender as UITableViewCell)!
		if indexPath.section == 0 {
			let searchValue = searchWords[indexPath.row]
			let type = TesSoMeSearchType(rawValue: self.searchTypeSegmentedControl.selectedSegmentIndex - 1)!
			var resultView = segue.destinationViewController as SearchResultViewController
			searchValue.setSearchValue(&resultView, withType: type)
		}
		closeKeyboard()
    }

}
