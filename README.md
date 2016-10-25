This project contains the source code used in the "Challenges for Static Analysis of Java Reflection – Literature Review and Empirical Study" paper submitted to ICSE 2017.

The analysis of the corpus, and certain parts of its construction is scripted in this Rascal project.

 - `src/build/slr/`: Scripts related to the automatic filtering of the SLR 
 - `src/build/corpus/`: Scripts related to downloading and extracting the corpus
 - `src/model/reflection/Grammar.rsc`: A Rascal ADT representation of the Reflection Grammar in Figure 1.
 - `src/model/reflection/Categories.rsc`: Another ADT representing the categories from Table 1, and the mapping between every production of the grammar and these categories.
 - `src/model/limitations/DifficultCases.rsc`: Implementation of the AST patterns described in Table 6.
 - `src/analyze/GatherASTs.rsc`: Gather the ASTs per project in the corpus, and save it for future analysis
 - `src/analyze/Productions.rsc`: Detect all reflections calls per project and map them onto the productions as defined in the paper.
 - `src/analyze/DifficultCases.rsc`: Detect all the difficult cases (limitations of approaches) per project.
 - `src/summarize/Productions.rsc`: Aggregate the reflection productions for Figure 3
 - `src/summarize/DifficultCases.rsc`: Aggregate the detected patterns for Table 7.
 - `src/data/`: Utility functions around data management (parsed java files and JRE models)
 - `src/util/`: Generic utility functions
 - `test/patterns/Difficult.java`: Example code that was used for initial development of patterns (followed by random sampling)
 - `data`: the location where (intermediate) results are saved. 
 - `data/corpus/`: extract the corpus here
