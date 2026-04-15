# The Interplay of Noun Phrase Complexity and Modification Type in Scientific Writing
Contribution to the Third Workshop on Quantitative Syntax (SyntaxFest 2025)

This repository contains the code used for the paper *The Interplay of Noun Phrase Complexity and Modification Type in Scientific Writing*, which was published in the Proceedings of the Third Workshop on Quantitative Syntax (SyntaxFest 2025). It is an analysis using the Royal Society Corpus (RSC, Fischer et al. 2020), a corpus containing the publications of the *Philosophical Transactions of the Royal Society of London*. We investigated the role of noun phrase (NP) complexity on modification type (post-modification vs. pre-modification).
The code in this repository was used for data preprocessing and analysis. Regression model summaries have been added as well.

## Research Question
Are more complex noun phrases (NPs) more likely to be post-modified than pre-modified?

## Data
RSC version 6.0.3 ("good sentences" version), parsed for Universal Dependencies (de Marneffe et al. 2021, Nivre et al. 2017), using the Python package *stanza* (Qi et al. 2020).

## Procedure
1. Stratified sampling using *preprocess/split_corpus_into_batches.py*: Split the corpus into 10 batches while preserving the distribution of files per year.
2. Extract NPs and their features (e.g. modification type, number of dependents, syntactic role, distance to head) as well as metadata (e.g. author, publication year, text type) from the first corpus batch using *preprocess/get_np_data.py*, resulting in the data file *noun_data_b1_v3.csv*.
3. Analyze the NPs using *analysis/analysis_20250304_d.R* (mixed-effects logistic regression model).

## References

Marie-Catherine de Marneffe, Christopher D. Manning, Joakim Nivre, and Daniel Zeman. 2021. Universal Dependencies. *Computational Linguistics*, 47(2):255–308.

Stefan Fischer, Jörg Knappen, Katrin Menzel, and Elke Teich. 2020. The Royal Society Corpus 6.0: Providing 300+ years of scientific writing for humanistic study. In *Proceedings of the Twelfth Language Resources and Evaluation Conference*, pages 794–802. European Language Resources Association.

Joakim Nivre, Daniel Zeman, Filip Ginter, and Francis Tyers. 2017. Universal Dependencies. In *Proceedings of the 15th Conference of the European Chapter of the Association for Computational Linguistics: Tutorial Abstracts*, Valencia, Spain. Association for Computational Linguistics.

Peng Qi, Yuhao Zhang, Yuhui Zhang, Jason Bolton, and Christopher D. Manning. 2020. Stanza: A Pythonnatural language processing toolkit for many human languages. In *Proceedings of the 58th Annual Meeting of the Association for Computational Linguistics:
System Demonstrations*, pages 101–108, Online. Association for Computational Linguistics.

## Citation

Isabell Landwehr. 2025. The Interplay of Noun Phrase Complexity and Modification Type in Scientific Writing. In *Proceedings of the Third Workshop on Quantitative Syntax (QUASY, SyntaxFest 2025)*, pages 72–82, Ljubljana, Slovenia. Association for Computational Linguistics.

```
@inproceedings{landwehr-2025-interplay,
    title = "The Interplay of Noun Phrase Complexity and Modification Type in Scientific Writing",
    author = "Landwehr, Isabell",
    editor = "Chen, Xinying  and
      Wang, Yaqin",
    booktitle = "Proceedings of the Third Workshop on Quantitative Syntax (QUASY, SyntaxFest 2025)",
    year = "2025",
    address = "Ljubljana, Slovenia",
    publisher = "Association for Computational Linguistics",
    url = "https://aclanthology.org/2025.quasy-1.10/",
    pages = "72--82",
}
```


