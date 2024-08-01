import { router } from '@kit.ArkUI';

@Entry
@Component
struct SplashPage {
  @State flag:boolean = false; //状态变量，用于控制组件出现或消失
  onPageShow() {
    //animateTo()用于触发动画效果
    animateTo({
      duration: 1000,
      curve: Curve.Linear,
      iterations: 1 ,
      onFinish:()=>{

        router.replaceUrl({url:'pages/Index'})
      }
    }, () => {
      this.flag = true;
    })
  }
  build() {
    RelativeContainer() {
      Column(){
        if(this.flag){
          Image($r('app.media.ic_logo'))
            .logoStyle()
            .transition({
              type:TransitionType.Insert,
              opacity:0,
              translate:{
                x:-150
              }
            })
          Text('快速单词记忆神器')
            .titleStyle()
            .transition({
              type:TransitionType.Insert,
              opacity:0,
              translate:{
                x:150
              }
            })
        }
      }
      .bgStyle()
    }
  }
}
@Styles function bgStyle(){
  .height('100%')
  .width('100%')
  .backgroundImage($r('app.media.img_splash_bg'))
  .backgroundImageSize({width:'100%',height:'100%'})
}
@Extend(Image) function logoStyle(){
  .width(90)
  .height(90)
  .margin({top:120})
}
@Extend(Text) function titleStyle(){
  .margin({top:30})
  .fontColor(Color.White)
  .fontSize(26)
  .fontWeight(900)
}
