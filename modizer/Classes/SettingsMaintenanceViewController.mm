//
//  SettingsMaintenanceViewController.m
//  modizer
//
//  Created by Yohann Magnien on 10/08/13.
//
//

#import "SettingsMaintenanceViewController.h"

#include <pthread.h>
extern pthread_mutex_t db_mutex;


@interface SettingsMaintenanceViewController ()
@end

@implementation SettingsMaintenanceViewController

@synthesize tableView,detailViewController,rootVC;

-(IBAction) goPlayer {
	[self.navigationController pushViewController:detailViewController animated:(detailViewController.mSlowDevice?NO:YES)];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *btn = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 61, 31)];
    [btn setBackgroundImage:[UIImage imageNamed:@"nowplaying_fwd.png"] forState:UIControlStateNormal];
    btn.adjustsImageWhenHighlighted = YES;
    [btn addTarget:self action:@selector(goPlayer) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[[UIBarButtonItem alloc] initWithCustomView: btn] autorelease];
    self.navigationItem.rightBarButtonItem = item;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) resetSettings {
    [SettingsGenViewController applyDefaultSettings];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle: @"Info" message:NSLocalizedString(@"Settings reseted",@"") delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alert show];
    
}

-(bool) resetRatingsDB {
	NSString *pathToDB=[NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"],DATABASENAME_USER];
	sqlite3 *db;
	int err;
	
	if (sqlite3_open([pathToDB UTF8String], &db) == SQLITE_OK){
		char sqlStatement[256];
		
		sprintf(sqlStatement,"UPDATE user_stats SET rating=NULL");
		err=sqlite3_exec(db, sqlStatement, NULL, NULL, NULL);
		if (err==SQLITE_OK){
		} else NSLog(@"ErrSQL : %d",err);
	};
	sqlite3_close(db);

    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle: @"Info" message:NSLocalizedString(@"Ratings reseted",@"") delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alert show];
    
	return TRUE;
}

-(bool) resetPlaycountDB {
	NSString *pathToDB=[NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"],DATABASENAME_USER];
	sqlite3 *db;
	int err;
	
	if (sqlite3_open([pathToDB UTF8String], &db) == SQLITE_OK){
		char sqlStatement[256];
		
		sprintf(sqlStatement,"UPDATE user_stats SET play_count=0");
		err=sqlite3_exec(db, sqlStatement, NULL, NULL, NULL);
		if (err==SQLITE_OK){
		} else NSLog(@"ErrSQL : %d",err);
	};
	sqlite3_close(db);
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle: @"Info" message:NSLocalizedString(@"Played Counters reseted",@"") delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alert show];
    
	return TRUE;
}

-(bool) cleanDB {
	NSString *pathToDB=[NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"],DATABASENAME_USER];
	sqlite3 *db;
	int err;
	BOOL success;
	NSFileManager *fileManager = [[NSFileManager alloc] init];
    
	pthread_mutex_lock(&db_mutex);
	
	if (sqlite3_open([pathToDB UTF8String], &db) == SQLITE_OK){
		char sqlStatement[256];
		char sqlStatement2[256];
		sqlite3_stmt *stmt;
		
		
		//First check that user_stats entries still exist
		sprintf(sqlStatement,"SELECT fullpath FROM user_stats");
		err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
		if (err==SQLITE_OK){
			while (sqlite3_step(stmt) == SQLITE_ROW) {
				success = [fileManager fileExistsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%s",sqlite3_column_text(stmt, 0)]]];
				if (!success) {//file does not exist
					//NSLog(@"missing : %s",sqlite3_column_text(stmt, 0));
					
					sprintf(sqlStatement2,"DELETE FROM user_stats WHERE fullpath=\"%s\"",sqlite3_column_text(stmt, 0));
					err=sqlite3_exec(db, sqlStatement2, NULL, NULL, NULL);
					if (err!=SQLITE_OK) {
						NSLog(@"Issue during delete of user_Stats");
					}
				}
			}
			sqlite3_finalize(stmt);
		} else NSLog(@"ErrSQL : %d",err);
		
		//Second check that playlist entries still exist
		sprintf(sqlStatement,"SELECT fullpath FROM playlists_entries");
		err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
		if (err==SQLITE_OK){
			while (sqlite3_step(stmt) == SQLITE_ROW) {
				success = [fileManager fileExistsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%s",sqlite3_column_text(stmt, 0)]]];
				if (!success) {//file does not exist
					NSLog(@"missing : %s",sqlite3_column_text(stmt, 0));
					
					sprintf(sqlStatement2,"DELETE FROM playlists_entries WHERE fullpath=\"%s\"",sqlite3_column_text(stmt, 0));
					err=sqlite3_exec(db, sqlStatement2, NULL, NULL, NULL);
					if (err!=SQLITE_OK) {
						NSLog(@"Issue during delete of playlists_entries");
					}
				}
			}
			sqlite3_finalize(stmt);
		} else NSLog(@"ErrSQL : %d",err);
		
		//No defrag DB
		sprintf(sqlStatement2,"VACUUM");
		err=sqlite3_exec(db, sqlStatement2, NULL, NULL, NULL);
		if (err!=SQLITE_OK) {
			NSLog(@"Issue during VACUUM");
		}
	};
	sqlite3_close(db);
	
	
	pthread_mutex_unlock(&db_mutex);
    [fileManager release];
	
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle: @"Info" message:NSLocalizedString(@"Database cleaned",@"") delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alert show];
    
	return TRUE;
}

-(void) recreateSamplesFolder {
 //   [rootViewControllerIphone createSamplesFromPackage:TRUE];
    [rootVC createSamplesFromPackage:TRUE];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle: @"Info" message:NSLocalizedString(@"Samples folder created",@"") delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alert show];
}

-(void) resetDB {
    [rootVC createEditableCopyOfDatabaseIfNeeded:TRUE quiet:TRUE];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle: @"Info" message:NSLocalizedString(@"Database reseted",@"") delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alert show];
}

-(void) removeCurrentCover {
    NSError *err;
    NSFileManager *mFileMngr=[[NSFileManager alloc] init];
    NSString *currentPlayFilepath =[detailViewController getCurrentModuleFilepath];
    if (currentPlayFilepath==nil) return;
    [mFileMngr removeItemAtPath:[NSString stringWithFormat:@"%@/%@/folder.jpg",NSHomeDirectory(),[currentPlayFilepath stringByDeletingLastPathComponent]] error:&err];
    [mFileMngr removeItemAtPath:[NSString stringWithFormat:@"%@/%@/folder.png",NSHomeDirectory(),[currentPlayFilepath stringByDeletingLastPathComponent]] error:&err];
    [mFileMngr removeItemAtPath:[NSString stringWithFormat:@"%@/%@/folder.gif",NSHomeDirectory(),[currentPlayFilepath stringByDeletingLastPathComponent]] error:&err];
    [mFileMngr removeItemAtPath:[NSString stringWithFormat:@"%@/%@.jpg",NSHomeDirectory(),[currentPlayFilepath stringByDeletingPathExtension]] error:&err];
    [mFileMngr removeItemAtPath:[NSString stringWithFormat:@"%@/%@.png",NSHomeDirectory(),[currentPlayFilepath stringByDeletingPathExtension]] error:&err];
    [mFileMngr removeItemAtPath:[NSString stringWithFormat:@"%@/%@.gif",NSHomeDirectory(),[currentPlayFilepath stringByDeletingPathExtension]] error:&err];
    [mFileMngr release];
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle: @"Info" message:NSLocalizedString(@"Cover removed",@"") delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alert show];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    return title;
}




- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    return footer;
}


- (UITableViewCell *)tableView:(UITableView *)tabView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    NSString *cellValue;
    const NSInteger TOP_LABEL_TAG = 1001;
    UILabel *topLabel;
    BButton *btn;
    
    UITableViewCell *cell = [tabView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
        cell.frame=CGRectMake(0,0,tabView.frame.size.width,40);
        
        [cell setBackgroundColor:[UIColor clearColor]];
        
        UIImage *image = [UIImage imageNamed:@"tabview_gradient40.png"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleToFill;
        cell.backgroundView = imageView;
        [imageView release];
        
        
        //
        // Create the label for the top row of text
        //
/*        topLabel = [[[UILabel alloc] init] autorelease];
        [cell.contentView addSubview:topLabel];
        //
        // Configure the properties for the text that are the same on every row
        //
        topLabel.tag = TOP_LABEL_TAG;
        topLabel.backgroundColor = [UIColor clearColor];
        topLabel.textColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
        topLabel.highlightedTextColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
        topLabel.font = [UIFont boldSystemFontOfSize:14];
        topLabel.lineBreakMode=UILineBreakModeMiddleTruncation;
        topLabel.opaque=TRUE;
        topLabel.numberOfLines=0;
        topLabel.frame= CGRectMake(4,
                                   0,
                                   tabView.bounds.size.width,
                                   40);
*/
        btn= [[[BButton alloc] initWithFrame:CGRectMake(tabView.bounds.size.width/2-80,
                                                      5,
                                                      160,
          
                                                       30)] autorelease];
        btn.tag=TOP_LABEL_TAG;
        [cell.contentView addSubview:btn];
        btn.autoresizingMask=UIViewAutoresizingFlexibleWidth;
        
        cell.accessoryView=nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
//        topLabel = (UILabel *)[cell viewWithTag:TOP_LABEL_TAG];
        btn = (BButton *)[cell viewWithTag:TOP_LABEL_TAG];
    }
    
    
    NSString *txt;
    switch (indexPath.row) {            
        case 0: //Clean DB
            txt=NSLocalizedString(@"Clean Database",@"");
            [btn setType:BButtonTypePrimary];
            [btn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [btn addTarget:self action:@selector(cleanDB) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 1: //Recreate Samples folder
            txt=NSLocalizedString(@"Recreate Samples folder",@"");
            [btn setType:BButtonTypePrimary];
            [btn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [btn addTarget:self action:@selector(recreateSamplesFolder) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 2: //Reset settings to default
            txt=NSLocalizedString(@"Reset settings to default",@"");
            [btn setType:BButtonTypeWarning];
            [btn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [btn addTarget:self action:@selector(resetSettings) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 3: //Remove current cover
            txt=NSLocalizedString(@"Remove current cover",@"");
            [btn setType:BButtonTypeDanger];
            [btn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [btn addTarget:self action:@selector(removeCurrentCover) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 4: //Reset Ratings
            txt=NSLocalizedString(@"Reset Ratings",@"");
            [btn setType:BButtonTypeDanger];
            [btn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [btn addTarget:self action:@selector(resetRatingsDB) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 5: //Reset played counter
            txt=NSLocalizedString(@"Reset Played Counters",@"");
            [btn setType:BButtonTypeDanger];
            [btn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [btn addTarget:self action:@selector(resetPlaycountDB) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 6: //Reset DB
            txt=NSLocalizedString(@"Reset Database",@"");
            [btn setType:BButtonTypeDanger];
            [btn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [btn addTarget:self action:@selector(resetDB) forControlEvents:UIControlEventTouchUpInside];
            break;

    }
    [btn setTitle:txt forState:UIControlStateNormal];
    
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tabView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tabView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tabView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tabView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tabView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tabView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}



@end