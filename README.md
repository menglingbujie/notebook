# Notebook

git通过文件系统找回未提交就被丢弃的文件 2016-09-01 

昨日因为手欠对一天的工作内容没有提交就丢弃了修改（sourceTree），git reflog对提交的有记录束手无策。

所以无论你如何reset --hard都没用。

因为都是针对提交过有提交id的记录才有用。
我只是在分支上丢了文件，而不是丢失分支，至于如何找回分支本人理解理论上应该通过reflog找到分支的commit id，然后reset过去。

接下来还是针对未提交（没有commit_id）的文件丢失，如何找回进行操作。

git有个命令git fsck。可以找到“悬挂”的文件（个人姑且理解为弃婴或孤儿吧）。对于这些孩子，其中有提交，有reset后丢失的文件

官方说法是：每次运行git add向索引中添加文件的时候，其实会向版本库中添加一个blob。如果你随后又修改了那个文件的内容，并且再次将该文件添加进索引中，那么就不会有任何提交会捕获之前添加到对象库中的那个blob对象，因此，变成了“悬挂”（孤儿）。

再次先还原一个数据丢失的场景

    git init
    echo "abc" >> file //写入文件
    git add file
    git commit -m "add file" //第一次提交

    echo "456" >> file //增加新功能
    git commit -am "add 456" //第二次提交

    git log //查看日志

    commit 6dd483bd5a1129fc53d0bf91b5b13fb36402e223
    Author: menglj <menglingbujie@gmail.com>
    Date:   Thu Sep 1 11:22:47 2016 +0800

    add 456

    commit 3852675f93a81c71d2883dc0dc41a759a7b22369
    Author: menglj <menglingbujie@gmail.com>
    Date:   Thu Sep 1 11:22:34 2016 +0800

    add file

    git reflog //查看提交操作记录

    6dd483b HEAD@{0}: commit: add 456
    3852675 HEAD@{1}: commit (initial): add file

    echo "bbb" >> file //增加新功能
    git add file //添加文件到暂存区
    git reset HEAD file //发现有问题，撤回add操作

    git reflog //查看历史操作

    6dd483b HEAD@{0}: commit: add 456
    3852675 HEAD@{1}: commit (initial): add file

    git fsck //查看文件系统

    Checking object directories: 100% (256/256), done.
    dangling blob 8cf58cb35152603f4ce80b2fd567df2cddd25fc9

    git show 8cf58cb35152603f4ce80b2fd567df2cddd25fc9 查看blob文件内容

    abc
    456
    bbb

经过了这些操作，会发现如官方所说只有git add文件版本库就会添加一个blob，之后撤回了blob文件（实际上打算对该文件进行二次操作），于是产生了一个“悬挂”。此时file文件内容依旧是abc 456 bbb，接着就是我把一天的工作内容销毁的操作了

    git checkout -- file //我用SourceTree执行了丢弃，把修改全部还原了

傻了，内容变回了第二次提交的内容了，abc 456。丢失了bbb。于是操作
    git reflog

    6dd483b HEAD@{0}: commit: add 456
    3852675 HEAD@{1}: commit (initial): add file

What？没有记录，无法git reset到执行版本，及时执行了git reset --hard也无济于事。

于是乎主角git fsck上场，上面我们执行过了该命令，这次我们对这些文件进行存储，执行：

    git fsck > blobfile //把blob文件存入临时文件

    cat blobfile //查看文件内容

    dangling blob 8cf58cb35152603f4ce80b2fd567df2cddd25fc9

    这就是一个“孤儿”，和上面的id一样，证明内容也一样，有bbb，可喜可贺，我之前的工作内容还在。于是赶紧把内容导出来,改名为file_bk方便之后用对比工具进行比对

    git show 8cf58cb35152603f4ce80b2fd567df2cddd25fc9 >> reback/file_bk

这里基本上算是结束了。因为blob有很多包括之前的操作（gc没有回收垃圾），我们需要一个个的查看并确认是否是自己修改的。可以写个shell脚本来做的。这里不是重点了。
