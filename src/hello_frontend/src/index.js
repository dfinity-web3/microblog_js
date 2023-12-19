import { hello_backend } from "../../declarations/hello_backend";

async function post(){
  let post_button = document.getElementById("post");
  post_button.disabled = true;
  let textarea = document.getElementById("message");
  let text = textarea.value;
  let otp_input = document.getElementById("otp");
  let otp = otp_input.value;
  let error_text = document.getElementById("error");
  error_text.innerText = "";
  try {
    await hello_backend.post(otp,text);
    textarea.value = "";
  }
  catch (err){
    console.log(err);
    error_text.innerText = "Post failed!";
  }
  post_button.disabled = false;
}

async function load_authors() {
  let authorsList = document.getElementById("authors");
  let authors = await hello_backend.get_followed_authors();
  authorsList.replaceChildren([]);
  authors.forEach(authorPrincipal => {
      let authorElement = document.createElement('li');
      authorElement.innerText = authorPrincipal.author; // 显示作者名
      authorElement.onclick = () => load_author_posts(authorPrincipal.principalId); // 使用 principalId 加载帖子
      authorsList.appendChild(authorElement);
  });
}

async function load_author_posts(principalId) {
  let postsSection = document.getElementById("author-posts");
  try {
      let posts = await hello_backend.get_posts_by_author(principalId);
      postsSection.replaceChildren([]);
      posts.forEach(post => {
          let postElement = document.createElement('p');
          postElement.innerText = post.text + " - Posted at " + new Date(post.time).toLocaleString();
          postsSection.appendChild(postElement);
      });
  } catch (err) {
      console.error("Failed to load posts: ", err);
      // 可以在页面上显示错误消息
  }
}


function convertTimestampToReadable(timeBigInt) {
  // 假设 Motoko 时间戳是基于纳秒的
  // 将纳秒转换为毫秒
  let timeInMilliseconds = Number(timeBigInt / BigInt(1_000_000));

  // 创建一个新的 Date 对象并格式化
  let date = new Date(timeInMilliseconds);
  return date.toLocaleString(); // 返回本地格式化的日期和时间字符串
}


var num_posts = 0;
async function load_posts(){
  let posts_section = document.getElementById("posts");
  let posts = await hello_backend.posts();
  if (num_posts == posts.length) 
      return ;
  num_posts = posts.length;
  posts_section.replaceChildren([]);

  for (var i = 0; i < posts.length; i++) {
    let post = document.createElement('p');
    let time = convertTimestampToReadable(BigInt(posts[i].time));
    post.innerText = posts[i].text + " - " + posts[i].author + " " + time;
    posts_section.appendChild(post);
  } 
}

async function onload(){
  let post_button = document.getElementById("post");
  post_button.onclick = post;
  load_posts();
  setInterval(load_posts,3000);
}

window.onload = onload;

