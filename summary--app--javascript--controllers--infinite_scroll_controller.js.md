60
IntersectionObserver auto-pagination. static targets scrollArea, pagination. connect: loading=false, lastFetchedHref=null, createObserver. threshold [0,1.0]. handleIntersect on visible. loadMore: guard !loading, find next <a>, guard lastFetchedHref, get(next.href, responseKind turbo-stream). disconnect: observer.disconnect(); observer=null. finally: loading=false.
