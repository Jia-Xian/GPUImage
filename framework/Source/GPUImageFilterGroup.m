#import "GPUImageFilterGroup.h"
#import "GPUImagePicture.h"

@implementation GPUImageFilterGroup

@synthesize terminalFilter = _terminalFilter;
@synthesize initialFilters = _initialFilters;
@synthesize inputFilterToIgnoreForUpdates = _inputFilterToIgnoreForUpdates;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    filters = [[NSMutableArray alloc] init];
    initialFilterTextureIndices = [[NSMutableArray alloc]init];
    [self deleteOutputTexture];
    
    return self;
}

#pragma mark -
#pragma mark Filter management

- (void)addFilter:(GPUImageOutput<GPUImageInput> *)newFilter;
{
    [filters addObject:newFilter];
}

- (GPUImageOutput<GPUImageInput> *)filterAtIndex:(NSUInteger)filterIndex;
{
    return [filters objectAtIndex:filterIndex];
}

- (int)filterCount;
{
    return [filters count];
}

#pragma mark -
#pragma mark Still image processing

- (CGImageRef)newCGImageFromCurrentlyProcessedOutputWithOrientation:(UIImageOrientation)imageOrientation;
{
    return [self.terminalFilter newCGImageFromCurrentlyProcessedOutputWithOrientation:imageOrientation];
}

- (void)prepareForImageCapture;
{
    [self.terminalFilter prepareForImageCapture];
}

#pragma mark -
#pragma mark GPUImageOutput overrides

- (void)setTargetToIgnoreForUpdates:(id<GPUImageInput>)targetToIgnoreForUpdates;
{
    [_terminalFilter setTargetToIgnoreForUpdates:targetToIgnoreForUpdates];
}

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    [_terminalFilter addTarget:newTarget atTextureLocation:textureLocation];
}

- (void)removeTarget:(id<GPUImageInput>)targetToRemove;
{
    [_terminalFilter removeTarget:targetToRemove];
}

- (void)removeAllTargets;
{
    [_terminalFilter removeAllTargets];
}

- (void)setFrameProcessingCompletionBlock:(void (^)(GPUImageOutput *, CMTime))frameProcessingCompletionBlock;
{
    [_terminalFilter setFrameProcessingCompletionBlock:frameProcessingCompletionBlock];
}

- (void (^)(GPUImageOutput *, CMTime))frameProcessingCompletionBlock;
{
    return [_terminalFilter frameProcessingCompletionBlock];
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in _initialFilters)
    {
        if (currentFilter != self.inputFilterToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [_initialFilters indexOfObject:currentFilter];
            NSInteger textureIndexOfInitialFilter = [[initialFilterTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [currentFilter newFrameReadyAtTime:frameTime atIndex:textureIndexOfInitialFilter];
            
        }
    }
}

- (void)setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in _initialFilters)
    {
        NSInteger indexOfObject = [_initialFilters indexOfObject:currentFilter];
        NSInteger textureIndexOfInitialFilter = [[initialFilterTextureIndices objectAtIndex:indexOfObject] intValue];
        
        [currentFilter setInputTexture:newInputTexture atIndex: textureIndexOfInitialFilter ];
    }
}

- (NSInteger)nextAvailableTextureIndex;
{
    [initialFilterTextureIndices removeAllObjects];
    
    for( unsigned int i = 0; i < [_initialFilters count]; i++ )
    {
        GPUImageOutput<GPUImageInput> *currentFilter = [_initialFilters objectAtIndex:i];
        [initialFilterTextureIndices addObject:[NSNumber numberWithInteger:currentFilter.nextAvailableTextureIndex] ];
    }
    return 0;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in _initialFilters)
    {
        //        [currentFilter setInputSize:newSize atIndex:textureIndex];
        
        NSInteger indexOfObject = [_initialFilters indexOfObject:currentFilter];
        NSInteger textureIndexOfInitialFilter = [[initialFilterTextureIndices objectAtIndex:indexOfObject] intValue];
        
        [currentFilter setInputSize:newSize atIndex:textureIndexOfInitialFilter];
        
    }
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in _initialFilters)
    {
        NSInteger indexOfObject = [_initialFilters indexOfObject:currentFilter];
        NSInteger textureIndexOfInitialFilter = [[initialFilterTextureIndices objectAtIndex:indexOfObject] intValue];
        
        [currentFilter setInputRotation:newInputRotation  atIndex:(NSInteger)textureIndexOfInitialFilter];
        
    }
}

- (void)forceProcessingAtSize:(CGSize)frameSize;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in filters)
    {
        [currentFilter forceProcessingAtSize:frameSize];
    }
}


- (CGSize)maximumOutputSize;
{
    // I'm temporarily disabling adjustments for smaller output sizes until I figure out how to make this work better
    return CGSizeZero;
    
    /*
     if (CGSizeEqualToSize(cachedMaximumOutputSize, CGSizeZero))
     {
     for (id<GPUImageInput> currentTarget in _initialFilters)
     {
     if ([currentTarget maximumOutputSize].width > cachedMaximumOutputSize.width)
     {
     cachedMaximumOutputSize = [currentTarget maximumOutputSize];
     }
     }
     }
     
     return cachedMaximumOutputSize;
     */
}

- (void)endProcessing;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in _initialFilters)
    {
        [currentFilter endProcessing];
    }
}

@end
