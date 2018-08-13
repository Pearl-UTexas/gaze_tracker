/**
	JS Functions for Human Gaze Tracking GUI
**/

var ros = new ROSLIB.Ros()
var canvas = {}
canvas.objects = []
var ctx = null
var canvas_doc = null

document.addEventListener("DOMContentLoaded", init, false)

function init(){
	canvas_doc = document.getElementById('canvas')
	
	ros.connect('ws://localhost:9090')

	var image_topic_param = new ROSLIB.Param({
    ros : ros,
    name : 'image_topic_name'
	})

	image_topic_param.get((image_topic) => {
		initViewer(image_topic)
	})

	if (canvas_doc.getContext){
		// use getContext to use the canvas for drawing
		ctx = canvas_doc.getContext('2d')

		initGazeListener()
		initYOLOListener()
	}
}

function initViewer(image_topic) {
	var viewer = document.getElementById('viewer')
	viewer.setAttribute("src", `http://localhost:8080/stream?topic=${image_topic}`)
}

function initGazeListener() {
	var gaze_listener = new ROSLIB.Topic({
		ros : ros,
		name : '/object_detector_bridge',
		messageType : 'object_detector/GazeTopic'
	})
	var mutual_msg = document.getElementById('mutual')

	gaze_listener.subscribe(function(message) {
		canvas.prediction = [message.coordinates.data[0],message.coordinates.data[1],20,20]
		canvas.face = [message.coordinates.data[2],message.coordinates.data[3],20,20]

		if (message.mutual.data){
			mutual_msg.style.color = "green"
			mutual_msg.innerHTML = "Mutual Gaze: True"
		}
		else{
			mutual_msg.style.color = "red"
			mutual_msg.innerHTML = "Mutual Gaze: False"
		}

		refresh_canvas()
	})
}

function initYOLOListener(){
	var yolo_listener = new ROSLIB.Topic({
		ros : ros,
		name : '/detector_node/detections',
		messageType : 'rail_object_detector/Detections'
	})

	yolo_listener.subscribe(function(message) {
		canvas.objects = message.objects
		// refresh_canvas()
	})
}

function refresh_canvas(){
	ctx.lineWidth = "3"
	ctx.clearRect(0, 0, canvas_doc.width, canvas_doc.height)

	if(canvas.objects.length>0){
		ctx.strokeStyle = "blue"
		for(var i = 0; i <canvas.objects.length; i++){
			var width = (canvas.objects[i].right_top_x)-(canvas.objects[i].left_bot_x)
			var height = (canvas.objects[i].right_top_y)-(canvas.objects[i].left_bot_y)
			var left_top_x = canvas.objects[i].left_bot_x
			var left_top_y = canvas.objects[i].left_bot_y + height
			ctx.strokeRect(canvas.objects[i].left_bot_x,canvas.objects[i].left_bot_y, width,height)
			ctx.font="15px Arial"
			ctx.fillText(canvas.objects[i].label,left_top_x,left_top_y-2)
			// canvas.objects = []
		}
	}

	if(typeof canvas.prediction !== 'undefined' && canvas.prediction.length>0){
		ctx.strokeStyle = "green"
		ctx.strokeRect(canvas.prediction[0],canvas.prediction[1],canvas.prediction[2],canvas.prediction[3])
	}

	if(typeof canvas.face !== 'undefined' && canvas.face.length>0) {
		ctx.strokeStyle = "purple"
		ctx.strokeRect(canvas.face[0],canvas.face[1],canvas.face[2],canvas.face[3])
		ctx.strokeStyle="yellow"
		ctx.beginPath()
		ctx.moveTo(canvas.face[0]+10, canvas.face[1]+10)
		ctx.lineTo(canvas.prediction[0]+10,canvas.prediction[1]+10)
		ctx.closePath()
		ctx.stroke()
		canvas.prediction = []
		canvas.face = []
	}
}

String.prototype.format = function() {
    var formatted = this
    for( var arg in arguments ) {
        formatted = formatted.replace("{" + arg + "}", arguments[arg])
    }
    return formatted
}

// If there is an error on the backend, an 'error' emit will be emitted.
ros.on('error', function(error) {
	console.log(error)
	document.getElementById('connection').style.color = "#FF0000"
	document.getElementById('connection').innerHTML = "Error in the backend!"
})
// Find out exactly when we made a connection.
ros.on('connection', function() {
	console.log('Connection made!')
	document.getElementById('connection').style.color = "#00D600"
	document.getElementById('connection').innerHTML = "Connected"
})
ros.on('close', function() {
	console.log('Connection closed.')
	document.getElementById('connection').style.color = "#FF0000"
	document.getElementById('connection').innerHTML = "Connection closed."
})
