## DailyDialog Dataset

Dailydialog is a multi-turn, dyadic corpus.
The dataset consists of text transcripts used by online English as a second language (ESL) instructors as examples of general conversations one expects to have throughout the day (hence "daily").

The dataset was originally published as part of the below paper,
and is available at: http://yanran.li/dailydialog.html .
```
@inproceedings{li:ijcnlp17,
    author = {Yanran Li and Hui Su and Xiaoyu Shen and Wenjie Li and Ziqiang Cao and Shuzi Niu},
    title = {DailyDialog: A Manually Labelled Multi-turn Dialogue Dataset},
    booktitle = {International Joint Conference on Natural Language Processing (IJCNLP)},
    year = {2017},
}
```

This distribution uses an updated version of the dataset that fixed some processing errors and formats the data as JSON objects.
This updated data was published as part of the below paper,
and is available at: https://github.com/declare-lab/conv-emotion/blob/master/bc-LSTM-pytorch/dailydialog.zip .
We provide a minimized version of this dataset here: https://linqs-data.soe.ucsc.edu/public/datasets/dailydialog/dailydialog-raw.zip .
```
@article{poria:access19,
    author = {Soujanya Poria and Navonil Majumder and Rada Mihalcea and Eduard Hovy},
    title = {Emotion Recognition in Conversation: Research Challenges, Datasets, and Recent Advances},
    journal = {IEEE Access},
    year = {2019},
    volume = {7},
    pages = {100943--100953},
}
```

The data consists of three files: `train.json`, `valid.json`, and `test.json`.
Note that these files are not JSON files,
but rather has a JSON object on each line.
Each JSON object corresponds to one full conversation/dialogue.
Each conversation is associated with a fold (train, valid, or test) and is labeled with the general topic of the conversation.
The JSON object also consists of a JSON array containing the utterances comprising the conversation,
and the corresponding emotion and act (intention) for each utterance.
