//
//  ViewController.m
//  sample-content
//
//  Created by Quickblox Team on 6/9/15.
//  Copyright (c) 2015 QuickBlox. All rights reserved.
//

#import "MainViewController.h"
#import "ImageViewController.h"
#import "ImageCollectionViewCell.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import <SVProgressHUD.h>

#import "AudioViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "WCSAlertController.h"

static NSString* const kImageCellIdentifier = @"ImageCollectionViewCellIdentifier";

@interface MainViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AudioViewControllerDelegate, AVAudioPlayerDelegate>
{
    AVAudioPlayer *player;
}

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) UILabel *footerLabel;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) NSMutableArray* blobs;
@property (nonatomic, strong) QBGeneralResponsePage* page;

@end

@implementation MainViewController

- (QBGeneralResponsePage *)page
{
    if (_page == nil) {
        _page = [QBGeneralResponsePage responsePageWithCurrentPage:0 perPage:10];
    }
    return _page;
}

- (UIImagePickerController *)imagePicker
{
    if (_imagePicker == nil) {
        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.allowsEditing = NO;
        _imagePicker.delegate = self;
        _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    return _imagePicker;
}

- (NSMutableArray *)blobs
{
    if (_blobs == nil) {
        _blobs = [NSMutableArray array];
    }
    return _blobs;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([QBSession currentSession].currentUser == nil) {
        __weak typeof(self)weakSelf = self;
        [SVProgressHUD showWithStatus:@"Logging in..."];
        [QBRequest logInWithUserLogin:@"sample_content" password:@"sample_content" successBlock:^(QBResponse *response, QBUUser *user) {
            [SVProgressHUD dismiss];
            __typeof(self) strongSelf = weakSelf;
            
            [strongSelf fetchNextPage];
        } errorBlock:^(QBResponse *response) {
            [SVProgressHUD showErrorWithStatus:@"Failed to login!"];
            NSLog(@"Response error %@:", response.error);
        }];
    } else {
        [self fetchNextPage];
    }
}

- (IBAction)addNewPicture:(id)sender
{
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[ImageViewController class]]) {
        NSIndexPath* indexPath = [self.collectionView indexPathForCell:sender];
        QBCBlob* image = self.blobs[indexPath.row];
        ImageViewController* viewController = segue.destinationViewController;
        viewController.imageBlob = image;
    } else if([segue.destinationViewController isKindOfClass:[AudioViewController class]]) {
        AudioViewController *viewController = segue.destinationViewController;
        viewController.delegate = self;
    }
}

#pragma mark -
#pragma mark Helpers

- (void)fetchNextPage
{
    self.page.currentPage += 1;
    __weak typeof(self)weakSelf = self;
    [SVProgressHUD showWithStatus:@"Loading next page..." maskType:SVProgressHUDMaskTypeNone];
    [QBRequest blobsForPage:self.page successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *blobs) {
        [SVProgressHUD dismiss];
        __typeof(self) strongSelf = weakSelf;
        
        [strongSelf.blobs addObjectsFromArray:blobs];
        [strongSelf.collectionView reloadData];
        
    } errorBlock:^(QBResponse *response) {
        [SVProgressHUD showErrorWithStatus:@"Failed to load page!"];
        NSLog(@"error: %@", response.error);
    }];
}

#pragma mark -
#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kImageCellIdentifier forIndexPath:indexPath];
    
    QBCBlob* blob = self.blobs[indexPath.row];
  
    if([blob.contentType isEqualToString:@"image/png"]){
        NSURL* url = [NSURL URLWithString:blob.privateUrl];
        [cell.spinnerView startAnimating];
        [cell.imageView sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [cell.spinnerView stopAnimating];
        }];
    }

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat value = self.collectionView.frame.size.width / 2.0f - 3.0f;
    
    return CGSizeMake(value, value);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.blobs.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    QBCBlob* file = self.blobs[indexPath.row];
    
    if (player.playing) {
        [player stop];
    }
    
    if([file.contentType isEqualToString:@"image/png"]){
        ImageViewController* viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ImageViewController"];
        viewController.imageBlob = file;
        [self.navigationController pushViewController:viewController animated:YES];
    }else{
        ImageCollectionViewCell *cell = (ImageCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
        
        [cell.spinnerView startAnimating];
        [QBRequest downloadFileWithUID:file.UID successBlock:^(QBResponse *response, NSData *fileData) {
            [cell.spinnerView stopAnimating];
            player = [[AVAudioPlayer alloc] initWithData:fileData error:nil];
            [player setDelegate:self];
            [player play];
        } statusBlock:^(QBRequest *request, QBRequestStatus *status) {
            NSLog(@"download progress: %f", status.percentOfCompletion);
        } errorBlock:^(QBResponse *response) {
            [cell.spinnerView stopAnimating];
            NSLog(@"Response error: %@", response.error);
        }];
        
    }
}

#pragma mark -
#pragma mark - UIScrollViewDidScroll

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    float scrollViewHeight = scrollView.frame.size.height;
    float scrollContentSizeHeight = scrollView.contentSize.height;
    float scrollOffset = scrollView.contentOffset.y;
    
    if (scrollOffset + scrollViewHeight == scrollContentSizeHeight) {
        [self fetchNextPage];
    }
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

// when photo is selected from gallery - > upload it to server
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *selectedImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImagePNGRepresentation(selectedImage);

    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    
    // Upload file to QuickBlox cloud
    //
    __weak __typeof(self)weakSelf = self;
    [SVProgressHUD showWithStatus:@"Uploading image"];
    
    [QBRequest TUploadFile:imageData fileName:@"iOS Content-Sample image" contentType:@"image/png" isPublic:NO
              successBlock:^(QBResponse *response, QBCBlob *blob) {

                  [SVProgressHUD dismiss];
                  
                  // Saving image directly SDWebImageCache
                  [[SDImageCache sharedImageCache] storeImage:selectedImage
                                                       forKey:[[SDWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:blob.privateUrl]]];
                  __typeof(self) strongSelf = weakSelf;
                  
                  [strongSelf addAudio:blob];
              } statusBlock:^(QBRequest *request, QBRequestStatus *status) {
                  [SVProgressHUD showProgress:status.percentOfCompletion status:@"Uploading image"];
              } errorBlock:^(QBResponse *response) {
                  [SVProgressHUD dismiss];
                  //
                  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error while uploading new file"
                                                                  message:[response.error description]
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles: nil];
                  [alert show];
              }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AudioViewControllerDelegate
- (void)addAudio:(QBCBlob *)blob
{
    [self.blobs addObject:blob];
    NSUInteger insertRow = self.blobs.count - 1;
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:insertRow inSection:0];
    [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    
}

@end
