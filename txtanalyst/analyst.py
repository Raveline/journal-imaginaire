'''This module leverages Python NLTK library to analyze
my mannerism, word usage, etc.'''

from nltk.probability import FreqDist
from nltk.corpus import PlaintextCorpusReader
from nltk.corpus import stopwords
from nltk.corpus.reader.util import read_regexp_block
from nltk.collocations import BigramAssocMeasures
from nltk.collocations import BigramCollocationFinder
from nltk.collocations import TrigramAssocMeasures
from nltk.collocations import TrigramCollocationFinder


class MarkdownCorpusReader(PlaintextCorpusReader):
    def __init__(self, root, file_id):
        super(MarkdownCorpusReader, self).__init__(self, root, file_id)
        CorpusReade


def read_block_no_metadata(stream):
    return read_regexp_block(stream, '(?!---|\w*:{1})')


def main():
    corpus_root = '../posts/'
    newcorpus = PlaintextCorpusReader(corpus_root, '.*',
                                      para_block_reader=read_block_no_metadata)
    corpus_words = [w.lower() for w in newcorpus.words() if w.isalpha()]
    corpus_sentences = newcorpus.sents()
    analyst = TextAnalyst(corpus_words, corpus_sentences, 'french')
    analyst.print_analyze()


class TextAnalyst(object):
    def __init__(self, words, sentences, language):
        self.num_words = len(words)
        self.unique_words = len(set(words))
        self.num_sentences = len(sentences)
        self.average_sentence_length = round(self.num_words / self.num_sentences)
        self.lexical_diversity = round(self.num_words / self.unique_words)

        fdist = FreqDist(words)
        stop_words = stopwords.words(language)
        not_stopwords = [w for w in words if w not in stop_words]
        fdist2 = FreqDist(not_stopwords)
        self.fifty_first_words = fdist.most_common(50)
        self.hundreds_nsw = fdist2.most_common(100)

        bigram_measures = BigramAssocMeasures()
        finder = BigramCollocationFinder.from_words(words)
        finder.apply_freq_filter(10)
        self.fifty_collocations = finder.nbest(bigram_measures.pmi, 50)

        trigram_measures = TrigramAssocMeasures()
        finder3 = TrigramCollocationFinder.from_words(words)
        finder3.apply_freq_filter(10)
        self.fifty_collocations3 = finder3.nbest(trigram_measures.pmi, 50)

    def print_analyze(self):
        print('------------------------------------------------')
        print('%50s : %d' % ('Number of words', self.num_words))
        print('%50s : %d' % ('Unique words', self.unique_words))
        print('%50s : %d' % ('Average sentence length (in words)',
                             self.average_sentence_length))
        print('%50s : %d' % ('Ratio words/unique words',
                             self.lexical_diversity))
        print('------------------------------------------------')
        print('20 MOST USED WORDS (ALL WORDS)')
        string = ', '.join([w for (w, c) in self.fifty_first_words])
        print(string)
        print('------------------------------------------------')
        print('50 MOST USED WORDS (NO STOPWORDS)')
        string = ', '.join([w for (w, c) in self.hundreds_nsw])
        print(string)
        print('------------------------------------------------')
        print('50 COLLOCATIONS OF 2 WORDS USED MORE THAN 10 TIMES')
        string = ', '.join([' '.join([w1, w2])
                            for (w1, w2) in self.fifty_collocations])
        print(string)
        print('------------------------------------------------')
        print('50 COLLOCATIONS OF 3 WORDS USED MORE THAN 10 TIMES')
        string = ', '.join([' '.join([w1, w2, w3])
                            for (w1, w2, w3) in self.fifty_collocations3])
        print(string)

if __name__ == "__main__":
    main()
