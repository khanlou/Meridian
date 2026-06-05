@preconcurrency import Foundation

func enableLineBufferedLogging() {
    let result = setvbuf(stdout, nil, _IOLBF, 16 * 1024)
    precondition(result == 0)
}
