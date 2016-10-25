module model::limitations::Collections

import lang::java::m3::Core;

import String;
import \data::JREs;


set[loc] randomAccessClasses = {
  |java+class:///com/sun/java/util/jar/pack/FixedList|,
  |java+class:///java/beans/beancontext/BeanContextServicesSupport|,
  |java+class:///java/beans/beancontext/BeanContextSupport|,
  |java+class:///java/util/AbstractCollection|,
  |java+class:///java/util/AbstractList|,
  |java+class:///java/util/ArrayList|,
  |java+class:///java/util/Collections/CheckedCollection|,
  |java+class:///java/util/Collections/CheckedList|,
  |java+class:///java/util/Collections/SynchronizedCollection|,
  |java+class:///java/util/Collections/UnmodifiableCollection|,
  |java+class:///java/util/Collections/UnmodifiableList|,
  |java+class:///java/util/LinkedList|,
  |java+class:///java/util/Vector|,
  |java+class:///java/util/concurrent/CopyOnWriteArrayList|,
  |java+class:///sun/awt/util/IdentityArrayList|,
  |java+class:///sun/awt/util/IdentityLinkedList|,
  |java+class:///sun/org/mozilla/javascript/internal/NativeArray|,
  |java+interface:///com/sun/corba/se/spi/ior/IORTemplateList|,
  |java+interface:///com/sun/org/apache/xerces/internal/xs/LSInputList|,
  |java+interface:///com/sun/org/apache/xerces/internal/xs/ShortList|,
  |java+interface:///com/sun/org/apache/xerces/internal/xs/StringList|,
  |java+interface:///com/sun/org/apache/xerces/internal/xs/XSNamespaceItemList|,
  |java+interface:///com/sun/org/apache/xerces/internal/xs/XSObjectList|,
  |java+interface:///com/sun/org/apache/xerces/internal/xs/datatypes/ByteList|,
  |java+interface:///com/sun/org/apache/xerces/internal/xs/datatypes/ObjectList|,
  |java+interface:///java/util/Collection|,
  |java+interface:///java/util/List|
};

set[loc] otherCollectionClasses = {
  |java+class:///com/sun/java/util/jar/pack/PropMap|,
  |java+class:///com/sun/net/httpserver/Headers|,
  |java+class:///java/awt/RenderingHints|,
  |java+class:///java/util/AbstractMap|,
  |java+class:///java/util/AbstractSet|,
  |java+class:///java/util/AbstractQueue|,
  |java+class:///java/util/ArrayDeque|,
  |java+class:///java/util/Collections/AsLIFOQueue|,
  |java+class:///java/util/Collections/CheckedMap/CheckedEntrySet|,
  |java+class:///java/util/Collections/CheckedMap|,
  |java+class:///java/util/Collections/CheckedSet|,
  |java+class:///java/util/Collections/CheckedSortedMap|,
  |java+class:///java/util/Collections/CheckedSortedSet|,
  |java+class:///java/util/Collections/SetFromMap|,
  |java+class:///java/util/Collections/SynchronizedList|,
  |java+class:///java/util/Collections/SynchronizedMap|,
  |java+class:///java/util/Collections/SynchronizedSet|,
  |java+class:///java/util/Collections/SynchronizedSortedMap|,
  |java+class:///java/util/Collections/SynchronizedSortedSet|,
  |java+class:///java/util/Collections/UnmodifiableMap|,
  |java+class:///java/util/Collections/UnmodifiableSet|,
  |java+class:///java/util/Collections/UnmodifiableSortedMap|,
  |java+class:///java/util/Collections/UnmodifiableSortedSet|,
  |java+class:///java/util/HashMap|,
  |java+class:///java/util/HashSet|,
  |java+class:///java/util/Hashtable|,
  |java+class:///java/util/IdentityHashMap|,
  |java+class:///java/util/LinkedHashMap|,
  |java+class:///java/util/LinkedHashSet|,
  |java+class:///java/util/TreeMap/KeySet|,
  |java+class:///java/util/TreeMap/NavigableSubMap|,
  |java+class:///java/util/TreeMap/SubMap|,
  |java+class:///java/util/TreeMap|,
  |java+class:///java/util/TreeSet|,
  |java+class:///java/util/WeakHashMap|,
  |java+class:///java/util/concurrent/ArrayBlockingQueue|,
  |java+class:///java/util/concurrent/ConcurrentHashMap|,
  |java+class:///java/util/concurrent/ConcurrentLinkedDeque|,
  |java+class:///java/util/concurrent/ConcurrentLinkedQueue|,
  |java+class:///java/util/concurrent/ConcurrentSkipListMap/KeySet|,
  |java+class:///java/util/concurrent/ConcurrentSkipListMap/SubMap|,
  |java+class:///java/util/concurrent/ConcurrentSkipListMap|,
  |java+class:///java/util/concurrent/ConcurrentSkipListSet|,
  |java+class:///java/util/concurrent/DelayQueue|,
  |java+class:///java/util/concurrent/LinkedBlockingDeque|,
  |java+class:///java/util/concurrent/LinkedBlockingQueue|,
  |java+class:///java/util/concurrent/LinkedTransferQueue|,
  |java+class:///java/util/concurrent/PriorityBlockingQueue|,
  |java+class:///java/util/concurrent/ScheduledThreadPoolExecutor/DelayedWorkQueue|,
  |java+class:///java/util/concurrent/SynchronousQueue|,
  |java+class:///java/util/jar/Attributes|,
  |java+class:///javax/script/SimpleBindings|,
  |java+class:///sun/misc/SoftCache|,
  |java+class:///sun/org/mozilla/javascript/internal/NativeObject|,
  |java+interface:///com/sun/corba/se/impl/orbutil/graph/Graph|,
  |java+interface:///com/sun/corba/se/spi/ior/IORTemplate|,
  |java+interface:///com/sun/corba/se/spi/ior/IOR|,
  |java+interface:///com/sun/corba/se/spi/ior/TaggedProfileTemplate|,
  |java+interface:///com/sun/corba/se/spi/ior/iiop/IIOPProfileTemplate|,
  |java+interface:///com/sun/org/apache/xerces/internal/xs/XSNamedMap|,
  |java+interface:///com/sun/xml/internal/ws/api/handler/MessageHandlerContext|,
  |java+interface:///java/beans/beancontext/BeanContextServices|,
  |java+interface:///java/beans/beancontext/BeanContext|,
  |java+interface:///java/util/Deque|,
  |java+interface:///java/util/Map|,
  |java+interface:///java/util/NavigableMap|,
  |java+interface:///java/util/NavigableSet|,
  |java+interface:///java/util/Queue|,
  |java+interface:///java/util/Set|,
  |java+interface:///java/util/SortedMap|,
  |java+interface:///java/util/SortedSet|,
  |java+interface:///java/util/concurrent/BlockingDeque|,
  |java+interface:///java/util/concurrent/BlockingQueue|,
  |java+interface:///java/util/concurrent/ConcurrentMap|,
  |java+interface:///java/util/concurrent/ConcurrentNavigableMap|,
  |java+interface:///java/util/concurrent/TransferQueue|,
  |java+interface:///javax/script/Bindings|,
  |java+interface:///javax/xml/ws/handler/LogicalMessageContext|,
  |java+interface:///javax/xml/ws/handler/MessageContext|,
  |java+interface:///javax/xml/ws/handler/soap/SOAPMessageContext|
};


set[str] getters = {
    // Collection
      "iterator"
    , "toArray"
    //|java+interface:///java/util/Deque|
    , "descendingIterator"
    , "element"
    , "getFirst"
    , "getLast"
    , "peek"
    , "peekFirst"
    , "peekLast" 
    , "poll"
    , "pollFirst"
    , "pollLast" 
    , "pop"
    //|java+interface:///java/util/List|
    , "get"
    , "listIterator"
    , "subList"
    //|java+interface:///java/util/Map|
    , "entrySet"
    , "keySet"
    , "values"
    //|java+interface:///java/util/NavigableSet|
    , "ceiling"
    , "descendingIterator"
    , "descendingSet"
    , "floor"
    , "headSet"
    , "higher"
    , "lower"
    , "subSet"
    , "tailSet"
    //|java+interface:///java/util/NavigableMap|
    , "ceilingKey"
    , "ceilingEntry"
    , "descendingKeySet"
    , "descendingMap"
    , "firstEntry"
    , "floorEntry"
    , "floorKey"
    , "headMap"
    , "higherEntry"
    , "higherKey"
    , "lastEntry"
    , "lowerEntry"
    , "lowerKey"
    , "navigableKeySet"
    , "pollFirstEntry"
    , "pollLastEntry"
    , "subMap"
    , "tailMap"
    //|java+interface:///java/util/SortedSet|
    , "first" 
    , "last"
    //|java+interface:///java/util/concurrent/BlockingDeque|
    , "take"
    //|java+interface:///java/util/SortedMap|
    , "firstKey"
    , "lastKey"
};

str getName(loc l) {
    name = l.file;
    parts = split("(", name);
    return parts[0];
}

@memo
tuple[set[loc] randoms, set[loc] others] getCollectionGettersMethods(loc root = |compressed+project://reflection-analysis/data/|) {
    model = getJRE7(root = root);
    randoms = {};
    others = {};
    for (<cl, m> <- model@containment, m.scheme == "java+method") {
        if (cl in randomAccessClasses && getName(m) in getters) {
            randoms += m;
        }
        if (cl in otherCollectionClasses && getName(m) in getters) {
            others += m;
        }
    }
    return <randoms, others>;
}
