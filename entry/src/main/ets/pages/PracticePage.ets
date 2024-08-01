import { borderStyles } from '@ohos.arkui.node';
import { AnswerStatus } from '../enums/AnswerStatus';
import { PracticeStatus } from '../enums/PracticeStatus';
import { getRandomQuestions, Question } from '../model/Questions';
import { promptAction } from '@kit.ArkUI';
import { OptionStatus } from '../enums/OptionStatus';
import { convertMillisecondsToTime } from '../utils/DateUtil';

@Component
export struct PracticePage {
  @State practiceStatus: PracticeStatus = PracticeStatus.Stopped; //练习状态
  @State totalCount: number = 10 //每次的测试题总数
  @State questions: Question[] = getRandomQuestions(this.totalCount); //题库，随机10道
  @State currentIndex: number = 0; //当前题目在题库中的index
  @State answerStatus: AnswerStatus = AnswerStatus.Answering //答题状态
  @State selectedOption: string = '' //选中的选项
  @State answeredCount: number = 0 //回答的总数
  @State rightCount: number = 0 //回答正确的总数
  timerController: TextTimerController = new TextTimerController()
  timeUsed: number = 0 //用时
  //哪里用，需要在哪里定义再一下自定义弹窗的controller,
  dialogController: CustomDialogController = new CustomDialogController({
    builder: ResultDialog({
      answeredCount: this.answeredCount,
      rightCount: this.rightCount,
      timeUsed: this.timeUsed,
      resetPractice: () => {
        this.questions = getRandomQuestions(this.totalCount)
        this.currentIndex = 0
        this.answeredCount = 0;
        this.rightCount = 0;
        this.timeUsed = 0;
        this.timerController.reset() //计时器重置
        this.answerStatus = AnswerStatus.Answering
      },
      startPractice: () => {
        this.startPractice()
      }
    }),
    //配置一下，弹窗的自定义样式才会生效
    customStyle: true,
    autoCancel: false  //点击遮罩层不让关闭
  })

  //开始测试
  startPractice() {
    this.practiceStatus = PracticeStatus.Running
    //开启定时器
    this.timerController.start()
  }

  //暂停测试
  pausePractice() {
    this.practiceStatus = PracticeStatus.Paused
    //停止定时器
    this.timerController.pause()
  }

  //结束测试
  stopPractice() {
    this.practiceStatus = PracticeStatus.Stopped
    //停止定时器
    this.timerController.pause()
    this.dialogController.open()
  }

  build() {
    Column({ space: 20 }) {
      //统计信息
      Column({ space: 10 }) {
        statItem({
          icon: $r('app.media.ic_accuracy'),
          name: '准确率',
          fontColor: Color.Black
        }) {
          //尾随闭包,不传会使用默认的builder
          Text((this.answeredCount === 0 ? 0 : this.rightCount / this.answeredCount * 100).toFixed() + '%')
            .width(100)
            .textAlign(TextAlign.Center)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
        }

        //进度
        statItem({
          icon: $r('app.media.ic_progress'),
          name: '进度',
          fontColor: Color.Black
        }) {
          //尾随闭包,不传会使用默认的builder
          Progress({ value: this.answeredCount, total: this.totalCount })
            .width(100)
            .color(Color.Orange)
            .backgroundColor(Color.Black)
        }

        //个数
        statItem({
          icon: $r('app.media.ic_progress'),
          name: '个数',
          fontColor: Color.Black
        }) {
          //尾随闭包,不传会使用默认的builder
          Button(this.totalCount.toString())
            .width(100)
            .backgroundColor('#fff')
            .fontColor(Color.Black)
            .enabled(this.practiceStatus === PracticeStatus.Stopped)
            .onClick(() => {
              TextPickerDialog.show({
                range: ['5', '10', '15', '20'],
                value: this.totalCount.toString(),
                onAccept: (result) => {
                  this.totalCount = Number(result.value)
                  //切换个数后重新拉取题目
                  this.questions = getRandomQuestions(this.totalCount)
                }
              })
            })
        }

        //计时器
        statItem({
          icon: $r('app.media.ic_timer'),
          name: '用时',
          fontColor: Color.Black
        }) {
          //尾随闭包,不传会使用默认的builder
          Row() {
            TextTimer({ controller: this.timerController })
              .onTimer((utc: number, elapsedTime: number) => {
                this.timeUsed = elapsedTime
              })
              .fontColor(Color.Black)
              .fontWeight(FontWeight.Bold)
          }.width(100)
          .justifyContent(FlexAlign.Center)

        }
      }
      .statBgStyle()

      //题目
      Column({ space: 10 }) {
        Text(this.questions[this.currentIndex].word)
          .fontSize(40)
          .fontWeight(900)
          .fontColor('#ff4f4e4e')
        Text(this.questions[this.currentIndex].sentence)
          .fontSize(16)
          .fontColor('#ff8f8c8c')

      }
      .width('90%')
      .borderRadius(20)
      .padding(10)

      //选项
      Column({ space: 10 }) {
        ForEach(this.questions[this.currentIndex].options, (option: string) => {
          OptionButton({
            option: option,
            answerStatus: this.answerStatus,
            answer: this.questions[this.currentIndex].answer,
            selectedOption: this.selectedOption
          })
            .enabled(this.answerStatus === AnswerStatus.Answering)
            .onClick(() => {
              //判断练习状态
              if (this.practiceStatus !== PracticeStatus.Running) {
                return promptAction.showToast({ message: '请先点击开始答题' })
              }
              //判断答案正误
              this.selectedOption = option

              //更新统计信息
              this.answeredCount++
              if (this.selectedOption === this.questions[this.currentIndex].answer) {
                this.rightCount++
              }

              //切换题目
              if (this.currentIndex < this.questions.length - 1) { //不是最后一题
                this.answerStatus = AnswerStatus.Answered
                setTimeout(() => {
                  this.currentIndex++
                  this.answerStatus = AnswerStatus.Answering
                }, 1000)
              } else { //最后一题
                this.stopPractice()
              }
            })
        })
      }
      .width('90%')
      .borderRadius(20)

      //按钮
      Column() {
        Row({ space: 50 }) {
          Button({ type: ButtonType.Capsule, stateEffect: true }) {
            Text('结束答题')
          }
          .controlButtonStyle({
            border: Color.Transparent,
            font: Color.White,
            bg: '#FA635F'
          })
          .enabled(this.practiceStatus !== PracticeStatus.Stopped)
          .onClick(() => {
            this.stopPractice()
          })

          Button({ type: ButtonType.Capsule, stateEffect: true }) {
            Text(this.practiceStatus === PracticeStatus.Running ? '暂停答题' : '开始答题')
          }
          .controlButtonStyle({
            border: Color.Transparent,
            font: Color.White,
            bg: '#1DBF7B'
          })
          .onClick(() => {
            if (this.practiceStatus === PracticeStatus.Running) {
              //暂停测试
              this.pausePractice()
            } else {
              this.startPractice()
            }

          })
        }
      }
      .width('90%')
      .borderRadius(20)
    }
    .pageStyle()
  }
}

//自定义弹窗
@CustomDialog
struct ResultDialog {
  answeredCount: number = 0 //回答的总数
  rightCount: number = 0 //回答正确的总数
  timeUsed: number = 0 //用时
  resetPractice: () => void = () => {
  }; //重置
  startPractice: () => void = () => {
  }; //再来一局重新开始
  dialogController: CustomDialogController = new CustomDialogController({
    builder: ResultDialog(),
  })

  build() {
    Column() {
      Image($r('app.media.ic_close'))
        .width(25)
        .height(25)
        .alignSelf(ItemAlign.End)
        .margin({ bottom: 5 })
        .onClick(() => {
          //关闭弹窗并重置题目和统计信息
          this.dialogController.close()
          this.resetPractice()
        })
      Column({ space: 10 }) {
        Image($r('app.media.img_post'))
          .width('100%')
          .borderRadius(10)
        statItem({
          icon: $r('app.media.ic_timer'),
          name: '用时',
          fontColor: Color.Black
        }) {
          //尾随闭包,不传会使用默认的builder
          Text(convertMillisecondsToTime(this.timeUsed))
            .width(50)
            .textAlign(TextAlign.Center)
        }

        statItem({
          icon: $r('app.media.ic_accuracy'),
          name: '准确率',
          fontColor: Color.Black
        }) {
          //尾随闭包,不传会使用默认的builder
          Text((this.answeredCount === 0 ? 0 : this.rightCount / this.answeredCount * 100).toFixed() + '%')
            .width(50)
            .textAlign(TextAlign.Center)
        }

        statItem({
          icon: $r('app.media.ic_count'),
          name: '个数',
          fontColor: Color.Black
        }) {
          //尾随闭包,不传会使用默认的builder
          Text(this.answeredCount.toString())
            .width(50)
            .textAlign(TextAlign.Center)
        }

        Divider()
        Row({ space: 30 }) {
          Button('再来一局')
            .controlButtonStyle({
              border: Color.Black,
              font: Color.Black,
              bg: Color.Transparent
            })
            .onClick(() => {
              //关闭弹窗并重置题目和统计信息
              this.dialogController.close()
              this.resetPractice()
              this.startPractice()
            })
          Button('登陆打卡')
            .controlButtonStyle({
              border: Color.Transparent,
              font: Color.White,
              bg: '#fd2eab42'
            })
            .onClick(() => {
              //关闭弹窗并重置题目和统计信息
              this.dialogController.close()
              this.resetPractice()
            })
        }
        .margin({ top: 15 })
      }
      .backgroundColor(Color.White)
      .width('100%')
      .padding(20)
      .borderRadius(5)
    }
    .width('80%')
    .backgroundColor(Color.Transparent)
  }
}

@Component
struct statItem {
  @Prop icon: Resource;
  @Prop name: string;
  @Prop fontColor: Color;
  //必须给个默认的builder
  @BuilderParam statComp: () => void = this.defaultBuilder;

  @Builder
  defaultBuilder() {
    Text('11')
  }

  build() {
    Row({ space: 10 }) {
      Image(this.icon)
        .width(14)
        .height(14)
      Text(this.name)
        .fontSize(14)
        .fontColor(this.fontColor)
        .fontWeight(900)

      Blank()
      this.statComp()
    }
    .width('100%')
    .height(30)

  }
}

@Component
struct OptionButton {
  @Prop option: string;
  @Prop answer: string; //正确答案
  @State optionStatus: OptionStatus = OptionStatus.Default
  //如果父组件中同时修改两个props,注意子组件中props的更新顺序是和声明顺序保持一致的，
  //先声明的先更新，后声明的后更新
  @Prop selectedOption: string;
  @Prop @Watch('onAnswerStatusChange') answerStatus: AnswerStatus; //是否在答题中

  onAnswerStatusChange() {
    if (this.option === this.answer) {
      this.optionStatus = OptionStatus.Right
    } else {
      if (this.option === this.selectedOption) {
        this.optionStatus = OptionStatus.Wrong
      } else {
        this.optionStatus = OptionStatus.Default
      }
    }
  }

  getBgColor() {
    switch (this.optionStatus) {
      case OptionStatus.Wrong:
        return '#FA635F'
      case OptionStatus.Right:
        return '#1DBF7B'
      default:
        return Color.White
    }
  }

  build() {
    Stack() {
      Button(this.option)
        .optionsButtonStyle({
          font: this.optionStatus === OptionStatus.Default ? Color.Black : Color.White,
          bg: this.getBgColor()
        })
      if (this.optionStatus === OptionStatus.Right) {
        Image($r('app.media.ic_right'))
          .width(22)
          .height(22)
          .offset({ x: 10 })
      } else if (this.optionStatus === OptionStatus.Wrong) {
        Image($r('app.media.ic_wrong'))
          .width(22)
          .height(22)
          .offset({ x: 10 })
      }
    }.alignContent(Alignment.Start)

  }
}

@Extend(Column)
function pageStyle() {
  .width('100%')
  .height('100%')
  .backgroundColor('#1900ccff')
  .justifyContent(FlexAlign.SpaceEvenly)
}

@Styles
function statBgStyle() {
  .width('90%')
  .backgroundColor('#ffffff')
  .borderRadius(10)
  .padding(20)
}

interface OptionsButtonColor {
  font: ResourceColor;
  bg: ResourceColor;
}

@Extend(Button)
function optionsButtonStyle(color: OptionsButtonColor) {
  .type(ButtonType.Normal)
  .width('90%')
  .backgroundColor(color.bg)
  .fontColor(color.font)
  .borderRadius(10)
  .padding(10)
}

interface ControlButtonColor {
  border: ResourceColor;
  font: ResourceColor;
  bg: ResourceColor;
}

@Extend(Button)
function controlButtonStyle(color: ControlButtonColor) {
  .width(100)
  .height(40)
  .fontSize(16)
  .borderWidth(1)
  .borderColor(color.border)
  .fontColor(color.font)
  .backgroundColor(color.bg)
}