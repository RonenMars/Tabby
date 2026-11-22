pub mod ffi;

use std::io;
use std::time::{Duration, Instant};
use crate::would_block_if_equal;

pub struct Capturer {
    width: usize,
    height: usize,
    display: Display,
    last_frame: Vec<u8>,
}

impl Capturer {
    pub fn new(display: Display) -> io::Result<Capturer> {
        ffi::init();
        
        let (width, height) = ffi::get_display_info();
        
        if !ffi::start_capture() {
            return Err(io::Error::new(
                io::ErrorKind::PermissionDenied,
                "Failed to start iOS screen capture. User permission may be required."
            ));
        }
        
        Ok(Capturer {
            width: width as usize,
            height: height as usize,
            display,
            last_frame: Vec::new(),
        })
    }
    
    pub fn width(&self) -> usize {
        self.width
    }
    
    pub fn height(&self) -> usize {
        self.height
    }
}

impl Drop for Capturer {
    fn drop(&mut self) {
        ffi::stop_capture();
    }
}

impl Capturer {
    // iOS has no `Frame` / `TraitCapturer::frame`. This stays an inherent method.
    pub fn frame<'a>(&'a mut self, timeout: Duration) -> io::Result<&'a [u8]> {
        let start = Instant::now();
        
        loop {
            if let Some((data, width, height)) = ffi::get_frame() {
                // Update dimensions if they changed
                self.width = width as usize;
                self.height = height as usize;
                
                // would_block_if_equal returns Err when frames are equal and
                // copies the new bytes into last_frame when they differ.
                if would_block_if_equal(&mut self.last_frame, &data).is_ok() {
                    return Ok(&self.last_frame);
                }
            }
            
            if start.elapsed() >= timeout {
                return Err(io::ErrorKind::WouldBlock.into());
            }
            
            // Small sleep to avoid busy waiting
            std::thread::sleep(Duration::from_millis(1));
        }
    }
}

#[derive(Debug, Clone, Copy)]
pub struct Display {
    pub primary: bool,
}

impl Display {
    pub fn primary() -> io::Result<Display> {
        Ok(Display { primary: true })
    }
    
    pub fn all() -> io::Result<Vec<Display>> {
        Ok(vec![Display { primary: true }])
    }
    
    pub fn width(&self) -> usize {
        let (width, _) = ffi::get_display_info();
        width as usize
    }
    
    pub fn height(&self) -> usize {
        let (_, height) = ffi::get_display_info();
        height as usize
    }
    
    pub fn name(&self) -> String {
        "iOS Display".to_string()
    }
    
    pub fn is_online(&self) -> bool {
        true
    }
    
    pub fn is_primary(&self) -> bool {
        self.primary
    }
    
    pub fn origin(&self) -> (i32, i32) {
        (0, 0)
    }
    
    pub fn id(&self) -> usize {
        1
    }
}

pub fn is_supported() -> bool {
    true
}

pub fn is_cursor_embedded() -> bool {
    true
}

pub fn is_mag_supported() -> bool {
    false
}