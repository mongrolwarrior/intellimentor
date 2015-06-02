#import <UIKit/UIKit.h>
#import "ViewLog.h"

/* search function from http://www.raywenderlich.com/16873/how-to-add-search-into-a-table-view
 other useful search sites:
 http://www.appcoda.com/how-to-add-search-bar-uitableview/
 http://www.appcoda.com/improve-detail-view-controller-storyboard-segue/
*/
@interface IMMainTable : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableArray *questionListData;

@property (strong,nonatomic) NSMutableArray *filteredSearchArray;
@property IBOutlet UISearchBar *questionSearchBar;

- (void)readDataForTable;

@end