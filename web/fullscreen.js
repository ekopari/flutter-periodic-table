const element = document.documentElement;

document.addEventListener('fullscreenchange', () => {
    notify_flutter_fullscreen(getFullscreenValue());
});

function getFullscreenValue() {
    let currentlyFullscreen = document.fullscreenElement;
    if (currentlyFullscreen) {
        currentlyFullscreen = true;
    } else {
        currentlyFullscreen = false;
    }
    return currentlyFullscreen;
}

function setFullscreenValue(fullscreenValue) {
    let currentlyFullscreen = getFullscreenValue();
    if (currentlyFullscreen == fullscreenValue) {
        return;
    }
    if (fullscreenValue) {
        element.requestFullscreen({navigationUI: "hide"});
    } else {
        document.exitFullscreen();
    }
}
window.getFullscreenValue = getFullscreenValue;
window.setFullscreenValue = setFullscreenValue;